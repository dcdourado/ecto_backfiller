defmodule EctoBackfiller.Consumer do
  require Logger
  use GenStage

  defstruct [:handle_batch]

  def start_link(%__MODULE__{} = config) do
    GenStage.start_link(__MODULE__, config)
  end

  # Callbacks

  @impl true
  def init(state) do
    {:consumer, state}
  end

  @impl true
  def handle_events(events, _from, %__MODULE__{handle_batch: handle_batch} = state) do
    Logger.info("Processing #{length(events)} events...")
    :ok = handle_batch.(events)
    {:noreply, [], state}
  end
end
