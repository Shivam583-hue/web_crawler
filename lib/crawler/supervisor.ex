defmodule Crawler.Supervisor do
  use Supervisor

  def start_link(_arg) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      Crawler.Queue,
      Crawler.RateLimiter,
      {Crawler.WorkerPool, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
