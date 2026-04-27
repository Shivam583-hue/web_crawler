defmodule Crawler.Parser do
  def extract_links(html, base_url) do
    html
    # parse html to flokii tree structure
    |> Floki.parse_document!()
    # find links, returns a list of nodes
    |> Floki.find("a[href]")
    # pulls out hrefs the list of nodes.
    |> Floki.attribute("href")
    # calls the normalise func, which acts as a url cleaner
    |> Enum.map(&normalize_url(&1, base_url))
    # removes invalid results
    |> Enum.filter(& &1)
    # removes duplicates
    |> Enum.uniq()
  end

  defp normalize_url(href, base_url) do
    cond do
      href in [""] ->
        nil

      String.starts_with?(href, "#") ->
        nil

      String.starts_with?(href, "javascript:") ->
        nil

      String.starts_with?(href, "mailto:") ->
        nil

      String.starts_with?(href, "tel:") ->
        nil

      true ->
        base = URI.parse(base_url)

        resolved =
          case URI.parse(href) do
            %URI{scheme: nil} -> URI.merge(base, href)
            uri -> uri
          end

        final = resolved |> Map.put(:fragment, nil)

        case final do
          %URI{scheme: s} when s in ["http", "https"] ->
            URI.to_string(final)

          _ ->
            nil
        end
    end
  rescue
    _ -> nil
  end
end
