defmodule Supershittycity.Repo do
  use Ecto.Repo,
    otp_app: :supershittycity,
    adapter: Ecto.Adapters.Postgres
end
