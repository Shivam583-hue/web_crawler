defmodule Crawler.Worker do
  alias Crawler.Stats
  alias Crawler.Http
  alias Crawler.RateLimiter
  alias Crawler.Queue

  @empty_retries 5
  @retry_sleep_ms 50

  def run(queue), do: loop(queue, @empty_retries)

  defp fetch_with_rate_limit(url) do
    domain = URI.parse(url).host
    try_fetch(url, domain, 0)
  end

  defp try_fetch(url, domain, retries) when retries < 5 do
    case RateLimiter.check_and_consume(domain) do
      :allow ->
        Http.fetch(url)

      {:deny, wait_ms} ->
        Process.sleep(wait_ms)
        try_fetch(url, domain, retries + 1)
    end
  end

  defp try_fetch(_url, _domain, _retries) do
    {:error, :rate_limited}
  end

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

    case fetch_with_rate_limit(url) do
      {:ok, html} ->
        links = Crawler.Parser.extract_links(html, url)

        Enum.each(links, fn link ->
          Queue.enqueue_if_new(queue, {link, depth - 1})
        end)

      {:error, reason} ->
        Stats.record_error(url, reason)
    end
  end
end
