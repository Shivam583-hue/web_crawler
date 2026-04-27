defmodule Crawler.Stats do
  use GenServer

  # ---------------CLIENT API--------------

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def record_error(url, reason) do
    GenServer.cast(__MODULE__, {:record_error, url, reason})
  end

  def summary do
    GenServer.call(__MODULE__, :summary)
  end

  # ---------------SERVER CALLBACKS--------------

  @impl true
  def init(:ok) do
    {:ok, %{errors: []}}
  end

  @impl true
  def handle_cast({:record_error, url, reason}, state) do
    new_errors = [{url, reason} | state.errors]
    {:noreply, %{state | errors: new_errors}}
  end

  @impl true
  def handle_call(:summary, _from, state) do
    {:reply,
     %{
       error_count: length(state.errors),
       errors: Enum.reverse(state.errors)
     }, state}
  end
end
