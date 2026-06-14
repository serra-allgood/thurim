defmodule ThurimClientApi.RateLimit do
  # Leaky Bucket algorithm chosen for consistent throughput,
  # see https://hammer.hexdocs.pm/Hammer.ETS.LeakyBucket.html
  # for information.
  use Hammer, backend: :ets, algorithm: :leaky_bucket
end
