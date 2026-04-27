defmodule Crawler.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Crawler.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Crawler.RootSupervisor]
    Supervisor.start_link(children, opts)
  end
end
