defmodule EctoBackfiller do
  @moduledoc """
  Orchestrator of a back-pressured backfill strategy for `Ecto` repos.

  Starts a producer process and dynamically start consumers, the amount of consumers is determined
  by the availability of resources on your infrastructure, such as available database connections
  or I/O usage.

  Define a module to execute the backfill, which must `use EctoBackfiller` and implement its callbacks.

  Lets imagine a silly example to illustrate the use of the library. Suppose you have a `User`
  schema described as:

  ```
  defmodule MyApp.Users.User do
    use Ecto.Schema

    schema do
      field :email_verified_at, :naive_datetime
    end
  end
  ```

  And later on, your business requirements takes you to add `email_verified` field as a boolean on
  the schema representing if the user has verified the email. Then you write up the migration and
  have to update the new column all existing users before execution of the migration.

  To do so, you can write a module using `EctoBackfiller` as:

  ```
  defmodule MyApp.Backfills.UserEmailVerifiedBackfill do
    use EctoBackfiller, repo: MyApp.Repo

    alias MyApp.Users
    alias MyApp.Users.User

    @impl true
    def query, do: Ecto.Queryable.to_query(User)

    @impl true
    def step, do: 5

    @impl true
    def handle_batch(users) do
      Enum.each(users, fn user ->
        if is_nil(user.email_verified_at) do
          {:ok, user} = Users.update(user, %{email_verified: false})
        else
          {:ok, user} = Users.update(user, %{email_verified: true})
        end
      end)
    end
  end
  ```

  Now you are ready to start executing it and to do so you must start the Supervisor, which will
  be named as the backfill module's name, or in other words, it is a unique proccess per backfill
  module.

  Inside the application IEx session:
  ```
  alias MyApp.Backfills.UserEmailVerifiedBackfill

  UserEmailVerifiedBackfill.start_link()
  :ok

  UserEmailVerifiedBackfill.add_consumer()
  :ok

  UserEmailVerifiedBackfill.start()
  :ok
  ```

  You may add or more consumers on the fly, based on how the application performs based on the step
  used and the number of consumers subscribed.
  """

  @doc "Queryable used on `Repo.all/2` to fetch chunks of data"
  @callback query() :: Ecto.Query.t()

  @doc "Amount of data fetched per step"
  @callback step() :: pos_integer()

  @doc "Handles the backfill logic given a list of data"
  @callback handle_batch(list(struct())) :: :ok

  defmacro __using__(opts \\ []) do
    quote do
      @behaviour EctoBackfiller

      alias EctoBackfiller.Consumer
      alias EctoBackfiller.DynamicSupervisor
      alias EctoBackfiller.Producer

      @doc """
      Starts supervisor and producer processes.
      """
      @spec start_link(offset :: non_neg_integer) :: :ok
      def start_link(offset \\ 0) do
        {:ok, sup} = DynamicSupervisor.start_link(name: __MODULE__)

        {:ok, producer} =
          DynamicSupervisor.start_producer(sup, %Producer{
            query: query(),
            step: step(),
            offset: offset,
            repo: Keyword.fetch!(unquote(opts), :repo)
          })

        :ok
      end

      @doc """
      Adds an inactive consumer to supervision tree.
      """
      @spec add_consumer() :: :ok
      def add_consumer do
        producer = get_producer()

        {:ok, consumer} =
          DynamicSupervisor.start_consumer(get_supervisor(), %Consumer{
            handle_batch: &handle_batch/1
          })

        if Producer.running?(producer) do
          {:ok, subscription} = GenStage.sync_subscribe(consumer, subscribe_opts(producer))
          Producer.add_consumer(producer, consumer, subscription)
        else
          Producer.add_consumer(producer, consumer)
        end
      end

      @doc """
      Subscribes all consumers that aren't already subscribed to producer.
      """
      @spec start() :: :ok
      def start do
        producer = get_producer()

        producer
        |> Producer.get_consumers()
        |> Enum.filter(fn
          {_consumer, nil} -> true
          {_consumer, _subscription} -> false
        end)
        |> Enum.each(fn {consumer, nil} ->
          {:ok, subscription} = GenStage.sync_subscribe(consumer, subscribe_opts(producer))
          Producer.put_subscription(producer, consumer, subscription)
        end)
      end

      @doc """
      Cancels all consumer subscriptions.
      """
      @spec cancel() :: :ok
      def cancel do
        producer = get_producer()

        producer
        |> Producer.get_consumers()
        |> Enum.filter(fn
          {_consumer, subscription} when is_reference(subscription) -> true
          _ -> false
        end)
        |> Enum.each(fn {consumer, subscription} ->
          :ok = GenStage.cancel({producer, subscription}, :shutdown)
        end)
      end

      defp get_supervisor, do: Process.whereis(__MODULE__)

      defp get_producer do
        children = Supervisor.which_children(get_supervisor())

        {:undefined, producer, :worker, [Producer]} =
          Enum.find(children, fn
            {_, pid, _, [Producer]} -> true
            _ -> false
          end)

        producer
      end

      defp subscribe_opts(producer) do
        [
          to: producer,
          max_demand: step(),
          min_demand: div(step(), 2),
          cancel: :transient
        ]
      end
    end
  end
end
