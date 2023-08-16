defmodule EctoBackfiller.Producer do
  use GenStage
  import Ecto.Query, only: [limit: 2, offset: 2]
  require Logger

  defstruct [:query, :step, :offset, :repo, :consumers]

  def start_link(%__MODULE__{} = config) do
    GenStage.start_link(__MODULE__, %{config | consumers: []})
  end

  def running?(producer) when is_pid(producer) do
    GenStage.call(producer, :running?)
  end

  def get_consumers(producer) when is_pid(producer) do
    GenStage.call(producer, :get_consumers)
  end

  def add_consumer(producer, consumer, subscription \\ nil)
      when is_pid(producer) and is_pid(consumer) and
             (is_reference(subscription) or is_nil(subscription)) do
    GenStage.cast(producer, {:add_consumer, consumer, subscription})
  end

  def put_subscription(producer, consumer, subscription)
      when is_pid(producer) and is_pid(consumer) and is_reference(subscription) do
    GenStage.cast(producer, {:put_subscription, consumer, subscription})
  end

  def cancel_subscription(producer, consumer) when is_pid(producer) and is_pid(consumer) do
    GenStage.cast(producer, {:cancel_subscription, consumer})
  end

  # Callbacks

  @impl true
  def init(state) do
    {:producer, state}
  end

  @impl true
  def handle_demand(
        demand,
        %__MODULE__{query: query, step: step, offset: offset, repo: repo} = state
      )
      when demand > 0 do
    Logger.info("Producing #{step} events from #{offset} offset...")

    events =
      query
      |> limit(^step)
      |> offset(^offset)
      |> repo.all()

    Logger.info("Produced #{length(events)} events from #{offset} offset")

    {:noreply, events, %{state | offset: offset + step}}
  end

  @impl true
  def handle_call(:running?, _from, state) do
    running? =
      Enum.any?(state.consumers, fn
        {_consumer, subscription} when is_reference(subscription) -> true
        _ -> false
      end)

    {:reply, running?, [], state}
  end

  @impl true
  def handle_call(:get_consumers, _from, state) do
    {:reply, state.consumers, [], state}
  end

  @impl true
  def handle_cast({:add_consumer, consumer, subscription}, state) do
    consumers = [{consumer, subscription} | state.consumers]
    {:noreply, [], %{state | consumers: consumers}}
  end

  @impl true
  def handle_cast({:put_subscription, consumer, subscription}, state) do
    consumers =
      Enum.map(state.consumers, fn
        {^consumer, _} -> {consumer, subscription}
        other -> other
      end)

    {:noreply, [], %{state | consumers: consumers}}
  end

  @impl true
  def handle_cast({:cancel_subscription, consumer}, state) do
    consumers =
      Enum.map(state.consumers, fn
        {^consumer, _} -> {consumer, nil}
        other -> other
      end)

    {:noreply, [], %{state | consumers: consumers}}
  end
end
