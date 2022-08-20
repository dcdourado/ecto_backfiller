defmodule EctoBackfiller.DynamicSupervisor do
  use DynamicSupervisor

  alias EctoBackfiller.Consumer
  alias EctoBackfiller.Producer

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, [], opts)
  end

  def start_producer(sup, %Producer{} = producer) when is_pid(sup) do
    spec = {Producer, producer}
    DynamicSupervisor.start_child(sup, spec)
  end

  def start_consumer(sup, %Consumer{} = consumer) when is_pid(sup) do
    spec = {Consumer, consumer}
    DynamicSupervisor.start_child(sup, spec)
  end

  @impl true
  def init(_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
