defmodule SupershittycityWeb.PageController do
  use SupershittycityWeb, :controller

  def index(conn, _params) do
    {:ok, poop} = Redix.command(:redix, ["GET", "poop"])
    render(conn, "index.html", poop: poop)
  end
end
