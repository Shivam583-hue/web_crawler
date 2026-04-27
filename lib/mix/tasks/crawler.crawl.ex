defmodule Mix.Tasks.Crawler.Crawl do
  use Mix.Task

  @shortdoc "Crawl a website"

  def run(args) do
    # ensures your app starts
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(args,
        switches: [url: :string, depth: :integer]
      )

    url = opts[:url]
    depth = opts[:depth] || 1

    if is_nil(url) do
      IO.puts("Please provide a --url")
      System.halt(1)
    end

    # call your crawler
    result = Crawler.run(url, depth)

    print_summary(result)
  end

  defp print_summary(%{pages: pages, errors: errors}) do
    IO.puts("\n--- Summary ---")
    IO.puts("Pages visited: #{pages}")
    IO.puts("Errors: #{errors}")
  end
end
