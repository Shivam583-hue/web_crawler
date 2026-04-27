defmodule Crawler.Coordinator do
  alias Crawler.Queue

  def run(seed_url, depth, concurrency) do
    queue = Crawler.Queue
    Queue.enqueue_if_new(queue, {seed_url, depth})

    Enum.each(1..concurrency, fn _ ->
      Crawler.WorkerPool.start_worker(queue)
    end)

    Process.sleep(100)
    wait_until_idle(queue)
    Queue.stats(queue)
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
