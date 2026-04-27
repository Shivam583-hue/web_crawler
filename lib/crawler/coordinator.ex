defmodule Crawler.Coordinator do
  alias Crawler.Reporter
  alias Crawler.Stats
  alias Crawler.Queue

  def run(seed_url, depth, concurrency) do
    queue = Crawler.Queue
    Queue.enqueue_if_new(queue, {seed_url, depth})

    Enum.each(1..concurrency, fn _ ->
      Crawler.WorkerPool.start_worker(queue)
    end)

    Process.sleep(100)
    wait_until_idle(queue)
    queue_stats = Queue.stats(queue)
    error_summary = Stats.summary()
    visited = Queue.all_visited(queue)
    Reporter.write_csv(visited, error_summary.errors, "crawler_report.csv")

    %{
      pages: queue_stats.visited,
      errors: error_summary.error_count
    }
  end

  defp wait_until_idle(queue) do
    state = :sys.get_state(queue)
    IO.inspect(state, label: "QUEUE STATE")

    if Queue.idle?(queue) do
      Process.sleep(150)
      if Queue.idle?(queue), do: :ok, else: wait_until_idle(queue)
    else
      Process.sleep(100)
      wait_until_idle(queue)
    end
  end
end
