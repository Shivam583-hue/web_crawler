defmodule Crawler.WorkerPool do
  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_worker(queue_pid) do
    spec = %{
      id: make_ref(),
      start: {Task, :start_link, [fn -> Crawler.Worker.run(queue_pid) end]},
      restart: :temporary
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
