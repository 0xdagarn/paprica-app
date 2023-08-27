defmodule Paprica.Repo do
  use Ecto.Repo,
    otp_app: :paprica,
    adapter: Ecto.Adapters.Postgres
end
