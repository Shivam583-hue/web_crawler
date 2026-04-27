defmodule Crawler.Http do
  def fetch(url) do
    try do
      case Req.get(url) do
        {:ok, %Req.Response{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %Req.Response{status: status}} ->
          {:error, {:http_error, status}}

        {:error, reason} ->
          {:error, reason}
      end

      # “If anything crashes with an exception inside try, catch it and return this tuple instead of letting the program crash.”
    rescue
      e ->
        {:error, {:exception, e}}
    end
  end
end
