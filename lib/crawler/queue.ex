defmodule Crawler.Queue do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def enqueue_if_new(pid, {url, depth}) do
    # call, not cast
    GenServer.call(pid, {:enqueue_if_new, {url, depth}})
  end

  def dequeue(pid) do
    GenServer.call(pid, :dequeue)
  end

  def worker_done(pid) do
    GenServer.call(pid, :worker_done)
  end

  def idle?(pid) do
    GenServer.call(pid, :idle?)
  end

  def stats(pid) do
    GenServer.call(pid, :stats)
  end

  @impl true
  def init(_) do
    {:ok, %{frontier: :queue.new(), visited: MapSet.new(), active: 0}}
  end

  @impl true
  def handle_call({:enqueue_if_new, {url, depth}}, _from, state) do
    already_visited = MapSet.member?(state.visited, url)

    already_in_frontier =
      :queue.to_list(state.frontier)
      |> Enum.any?(fn {u, _} -> u == url end)

    if already_visited or already_in_frontier do
      {:reply, :duplicate, state}
    else
      new_frontier = :queue.in({url, depth}, state.frontier)
      {:reply, :ok, %{state | frontier: new_frontier}}
    end
  end

  @impl true
  def handle_call(:dequeue, _from, state) do
    case :queue.out(state.frontier) do
      {{:value, {url, depth}}, new_queue} ->
        new_state = %{
          state
          | frontier: new_queue,
            visited: MapSet.put(state.visited, url),
            active: state.active + 1
        }

        {:reply, {:ok, {url, depth}}, new_state}

      {:empty, _} ->
        {:reply, :empty, state}
    end
  end

  @impl true
  def handle_call(:worker_done, _from, state) do
    {:reply, :ok, %{state | active: state.active - 1}}
  end

  @impl true
  def handle_call(:idle?, _from, state) do
    {:reply, state.active <= 0 and :queue.is_empty(state.frontier), state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{frontier: :queue.len(state.frontier), visited: MapSet.size(state.visited)}, state}
  end
end
