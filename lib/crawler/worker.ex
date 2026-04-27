defmodule Crawler.Worker do
  alias Crawler.Queue

  @empty_retries 5
  @retry_sleep_ms 50

  def run(queue), do: loop(queue, @empty_retries)

  defp loop(queue, retries_left) do
    case Queue.dequeue(queue) do
      {:ok, {url, depth}} ->
        process(url, depth, queue)
        Queue.worker_done(queue)
        loop(queue, @empty_retries)

      :empty when retries_left > 0 ->
        Process.sleep(@retry_sleep_ms)
        loop(queue, retries_left - 1)

      :empty ->
        :ok
    end
  end

  defp process(_url, depth, _queue) when depth <= 0, do: :ok

  defp process(url, depth, queue) do
    IO.puts("Visited: #{url}")

    case Crawler.Http.fetch(url) do
      {:ok, html} ->
        links = Crawler.Parser.extract_links(html, url)

        Enum.each(links, fn link ->
          Queue.enqueue_if_new(queue, {link, depth - 1})
        end)

      {:error, _} ->
        :ok
    end
  end
end
