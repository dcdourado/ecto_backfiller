defmodule EctoBackfiller.Producer do
  @moduledoc """
  A GenStage producer that produces events from a given query.

  The producer will produce events from the give `query` in batches of
  `step` size. The events will be ordered by the `seek_col` column. The
  `last_seeked_val` is the last event `seek_col` value produced and will
  be used to determine the starting point of the next batch.
  """

  use GenStage
  import Ecto.Query, only: [limit: 2, order_by: 3, where: 3]
  require Logger

  defstruct [:query, :step, :seek_col, :last_seeked_val, :stop_seek_val, :repo, :consumers]

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
        %__MODULE__{
          query: query,
          step: step,
          seek_col: seek_col,
          last_seeked_val: last_seeked_val,
          stop_seek_val: stop_seek_val,
          repo: repo
        } = state
      )
      when demand > 0 do
    if is_number(last_seeked_val) and is_number(stop_seek_val) and
         last_seeked_val >= stop_seek_val do
      Logger.warn("Producer has reached the stop seek value: #{stop_seek_val}.")
      {:noreply, [], state}
    else
      last_seeked_val_text =
        if last_seeked_val != nil, do: inspect(last_seeked_val), else: "the beginning"

      Logger.info("Producing #{step} events from: #{last_seeked_val_text}...")

      events =
        query
        |> apply_seek(seek_col, last_seeked_val)
        |> order_by([_a], {:asc, ^seek_col})
        |> limit(^step)
        |> repo.all(timeout: :infinity)

      Logger.info("Produced #{length(events)} events from: #{last_seeked_val_text}.")

      if length(events) > 0 do
        last_event = Enum.at(events, -1)
        {:noreply, events, %{state | last_seeked_val: Map.fetch!(last_event, seek_col)}}
      else
        {:noreply, [], state}
      end
    end
  end

  defp apply_seek(query, _seek_col, nil), do: query

  defp apply_seek(query, seek_col, last_seeked_val),
    do: where(query, [a], field(a, ^seek_col) > ^last_seeked_val)

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
