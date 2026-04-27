defmodule Crawler.Core do
  alias Crawler.Http
  alias Crawler.Parser
  alias Crawler.Queue

  def crawl(_queue, 0), do: :ok

  def crawl(queue) do
    case Queue.dequeue(queue) do
      :empty ->
        :ok

      {:ok, {url, current_depth}} ->
        if current_depth > 0 do
          case Http.fetch(url) do
            {:ok, html} ->
              links = Parser.extract_links(html, url)

              Enum.each(links, fn link ->
                Queue.enqueue_if_new(queue, {link, current_depth - 1})
              end)

            {:error, _} ->
              :ok
          end
        end

        crawl(queue)
    end
  end
end
