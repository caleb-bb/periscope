defmodule Periscope.Repo do
  use Ecto.Repo,
    otp_app: :periscope,
    adapter: Ecto.Adapters.Postgres
end
