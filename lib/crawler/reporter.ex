defmodule Crawler.Reporter do
  alias Crawler.CSV

  def write_csv(visited_urls, errors, path) do
    visited_rows =
      Enum.map(visited_urls, fn url ->
        [url, "ok"]
      end)

    error_rows =
      Enum.map(errors, fn {url, reason} ->
        [url, "error:#{inspect(reason)}"]
      end)

    rows = visited_rows ++ error_rows

    iodata =
      Enum.map(rows, fn row ->
        Enum.join(row, ",") <> "\n"
      end)

    binary = IO.iodata_to_binary(iodata)
    binary = IO.iodata_to_binary(iodata)

    File.write!(path, binary)

    IO.puts("Report saved to #{path}")
  end
end
