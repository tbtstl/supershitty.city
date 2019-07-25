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
    # https://data.sfgov.org/resource/vw6y-z8j6.json
    # https://data.sfgov.org/resource/vw6y-z8j6.json?$where=starts_with(service_subtype,%20%27Human%20or%20Animal%27)%20AND%20closed_date%20%3E%20%272019-07-20T06:25:32%27&$select=(count(service_request_id))
    {:ok, http_conn} = Mint.HTTP.connect(:http, "data.sfgov.org", 80)
    {:ok, http_conn, _request_ref} = Mint.HTTP.request(http_conn, "GET", "/resource/vw6y-z8j6.json?$where=starts_with(service_subtype,%20%27Human%20or%20Animal%27)%20AND%20closed_date%20%3E%20%272019-07-20T06:25:32%27&$select=(count(service_request_id))", [], "")
    receive do
      message ->
        {:ok, _http_conn, responses} = Mint.HTTP.stream(http_conn, message)
        [{:status, _, 200}, {:headers, _, _}, {:data, _,  body}, {:done, _}] = responses
        {:ok, [%{"count_service_request_id" => count}]}= Jason.decode(body)
        {:ok, conn} = Redix.start_link("redis://localhost:6379/3")
        Redix.command(conn, ["SET", "poop", count])
    end
  end
end
