defmodule Supershittycity.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Supershittycity.Repo,
      # Start the endpoint when the application starts
      SupershittycityWeb.Endpoint,
      # Starts a worker by calling: Supershittycity.Worker.start_link(arg)
      # {Supershittycity.Worker, arg},

      Supershittycity.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Supershittycity.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SupershittycityWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Fetch data from SF 311
  def fetch_poop do
    {:ok, conn} = Redix.start_link("redis://localhost:6379/3")
    Redix.command(conn, ["SET", "poop", 1])
  end
end
