defmodule Supershittycity.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  use Supervisor
  use Timex
  require Logger

  def start(_type, _args) do
    redis_conn = Application.get_env(:redix, :conn)
    redis_name = Application.get_env(:redix, :name)
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Supershittycity.Repo,
      # Start the endpoint when the application starts
      SupershittycityWeb.Endpoint,
      # Starts a worker by calling: Supershittycity.Worker.start_link(arg)
      # {Supershittycity.Worker, arg},

      Supershittycity.Scheduler,

      worker(Redix, [redis_conn, redis_name])
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
    date = Timex.now
    |> Timex.shift(days: -7)
    |> Timex.format!("{ISO:Extended}")
    |> String.split(".")
    |> List.first
    {:ok, http_conn, _request_ref} = Mint.HTTP.request(http_conn, "GET", "/resource/vw6y-z8j6.json?$where=starts_with(service_subtype,%20%27Human%20or%20Animal%27)%20AND%20requested_datetime%20%3E%20%27#{date}%27&$select=(count(service_request_id))", [], "")
    receive do
      message ->
        Mint.HTTP.stream(http_conn, message)
        |> case do
             {:error, reason} -> Logger.error("Could not connect to sf.gov: #{reason}")
             {:ok, _, responses} -> handle_response(responses)
           end
    end
  end

  def handle_response(responses) do
    case responses do
      [{:status, _, 200}, {:headers, _, _}, {:data, _,  body}, {:done, _}] -> parse_body(body)
      [{:status, _, code} | _] -> Logger.error("sf.gov returned status #{code}")
    end
  end

  def parse_body(body) do
    Jason.decode(body)
    |> case do
         {:ok, [%{"count_service_request_id" => count}]} -> set_poop(count)
         _ -> Logger.error("Could not parse JSON: #{body}")
       end
  end

  def set_poop(count) do
    Redix.command(:redix, ["SET", "poop", count])
    |> case do
         {:ok, _} -> Logger.info("Set #{count} poop in redis")
         {:error, reason} -> Logger.error("Could not set poop in redis: #{reason}")
       end
  end
end
