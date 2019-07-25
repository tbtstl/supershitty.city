defmodule SupershittycityWeb.PageController do
  use SupershittycityWeb, :controller

  def index(conn, _params) do
    {:ok, redis_conn} = Redix.start_link("redis://localhost:6379/3")
    {:ok, poop} = Redix.command(redis_conn, ["GET", "poop"])
    render(conn, "index.html", poop: poop)
  end
end
