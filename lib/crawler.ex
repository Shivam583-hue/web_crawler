defmodule Crawler do
  alias Crawler.Coordinator

  def run(url, depth, opts \\ []) do
    concurrency = Keyword.get(opts, :concurrency, 10)

    stats = Coordinator.run(url, depth, concurrency)

    %{
      pages: stats.pages,
      errors: 0
    }
  end
end
