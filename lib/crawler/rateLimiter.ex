defmodule Crawler.RateLimiter do
  use GenServer

  @capacity 5
  @refill_rate 1.0
  @min_wait_ms 200

  # ---------------CLIENT API--------------

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def check_and_consume(domain) do
    GenServer.call(__MODULE__, {:check_and_consume, domain})
  end

  # ------------------SERVER CALLBACKS------------

  @impl true
  def init(:ok) do
    {:ok, %{buckets: %{}}}
  end

  @impl true
  def handle_call({:check_and_consume, domain}, _from, state) do
    now = System.monotonic_time(:millisecond)

    bucket = get_or_init_bucket(state.buckets, domain, now)

    elapsed = now - bucket.last_refill

    new_tokens =
      min(
        @capacity * 1.0,
        bucket.tokens + elapsed * @refill_rate / 1000
      )

    if new_tokens >= 1.0 do
      updated_bucket = %{
        tokens: new_tokens - 1.0,
        last_refill: now
      }

      new_state = put_in(state.buckets[domain], updated_bucket)

      {:reply, :allow, new_state}
    else
      updated_bucket = %{
        tokens: new_tokens,
        last_refill: now
      }

      new_state = put_in(state.buckets[domain], updated_bucket)

      {:reply, {:deny, @min_wait_ms}, new_state}
    end
  end

  defp get_or_init_bucket(buckets, domain, now) do
    Map.get(buckets, domain, %{
      tokens: @capacity * 1.0,
      last_refill: now
    })
  end
end
