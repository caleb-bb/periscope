defmodule PeriscopeWeb.PageController do
  use PeriscopeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
