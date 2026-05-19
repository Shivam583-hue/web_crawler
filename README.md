# Crawler

A concurrent web crawler built in Elixir using OTP — supervised worker pool, GenServer-backed queue, per-domain rate limiting, and CSV output.

## Architecture

```
Crawler.Supervisor
├── Crawler.Queue         (GenServer)   — frontier + visited set + active worker counter
├── Crawler.WorkerPool    (DynamicSupervisor) — spawns and supervises Task workers
├── Crawler.RateLimiter   (GenServer)   — token bucket per domain
└── Crawler.Stats         (GenServer)   — error collection
```

Workers are `Task` processes under a `DynamicSupervisor`. They dequeue URLs, fetch, parse links, and re-enqueue — all talking to the `Queue` GenServer as the single source of truth. No shared memory, no locks.



## How it works

1. `Coordinator` seeds the `Queue` with `{seed_url, depth}` and spawns N workers
2. Each `Worker` loops: dequeue → rate limit check → fetch → parse → enqueue new links
3. Depth is stored per URL tuple in the frontier — children are enqueued at `depth - 1`, skipped at `depth == 0`
4. `Queue` tracks `active` (URLs in flight) + `visited` (MapSet). Termination fires when both `active == 0` and frontier is empty
5. `RateLimiter` uses lazy token bucket refill — tokens are recalculated on demand using `System.monotonic_time/1`, no timer process needed
6. Results are written to `crawl_report.csv`

## Usage

```bash
mix deps.get
mix crawler.crawl --url https://example.com --depth 2
```


Example:
```bash
mix crawler.crawl --url http://localhost:3000 --depth 2
```

Options:

| Flag | Default | Description |
|------|---------|-------------|
| `--url` | required | Seed URL to start crawling from |
| `--depth` | `1` | How many hops from the seed URL |

Output is printed to stdout and saved to `crawl_report.csv` in the project root.

## Example output

```
Visited: https://example.com
Visited: https://example.com/about
Visited: https://example.com/contact

--- Summary ---
Pages visited: 3
Errors: 0
```

```csv
https://example.com,ok
https://example.com/about,ok
https://example.com/contact,ok
```

## Configuration

Rate limiter defaults are set as module attributes in `Crawler.RateLimiter`:

```elixir
@capacity    5      # max tokens per domain (burst size)
@refill_rate 1.0    # tokens per second
@min_wait_ms 200    # sleep duration when a request is denied
```

Concurrency is set in `Crawler.Coordinator`:

```elixir
def run(seed_url, depth, concurrency \\ 10)
```

## Modules

| Module | Role |
|--------|------|
| `Crawler.Queue` | GenServer owning frontier (`:queue`), visited (`MapSet`), and active counter |
| `Crawler.Worker` | Task loop — dequeue, fetch, parse, enqueue, repeat |
| `Crawler.WorkerPool` | DynamicSupervisor that starts worker Tasks |
| `Crawler.RateLimiter` | GenServer with per-domain lazy token bucket |
| `Crawler.Stats` | GenServer collecting `{url, reason}` error tuples |
| `Crawler.Coordinator` | Orchestrates seed, worker spawn, idle wait, and reporting |
| `Crawler.Http` | `Req.get/2` wrapper returning `{:ok, html}` or `{:error, reason}` |
| `Crawler.Parser` | Floki-based link extractor with URL normalization via `URI` |
| `Crawler.Reporter` | Writes visited URLs and errors to CSV using `NimbleCSV` |

## Dependencies

- [`req`](https://hex.pm/packages/req) — HTTP client
- [`floki`](https://hex.pm/packages/floki) — HTML parser
- [`nimble_csv`](https://hex.pm/packages/nimble_csv) — CSV generation

