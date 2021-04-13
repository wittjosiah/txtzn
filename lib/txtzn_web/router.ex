defmodule TxtznWeb.Router do
  use TxtznWeb, :router

  alias CtznClient.{Accounts, Session, Supervisor}
  alias Plug.Conn

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TxtznWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_txtzn_session
    plug :init_ctzn_ws
  end

  scope "/", TxtznWeb do
    pipe_through :browser

    live "/", LandingLive, :index
    live "/feed", FeedLive, :index
    live "/signin", SessionLive, :index
    post "/signin", SessionController, :sign_in
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: TxtznWeb.Telemetry
    end
  end

  defp put_txtzn_session(%Conn{} = conn, _) do
    if client_id = get_session(conn, :ctzn_client_id) do
      assign(conn, :ctzn_client_id, client_id)
    else
      id = UUID.uuid4()

      conn
      |> put_session(:ctzn_client_id, id)
      |> assign(:ctzn_client_id, id)
    end
  end

  defp init_ctzn_ws(%Conn{assigns: %{ctzn_client_id: id}} = conn, _) do
    with %Session{session_id: session_id, user_id: user_id} <- get_session(conn, :ctzn_session),
         [_, host] <- String.split(user_id, "@"),
         {:ok, pid} <- lookup_or_start_ws(id, host) do
      Accounts.resume_session(pid, session_id)
      assign(conn, :ctzn_ws_pid, pid)
    else
      _ -> conn
    end
  end

  defp lookup_or_start_ws(client_id, host) do
    case Registry.lookup(Registry.CtznClient, client_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> Supervisor.start_child(client_id: client_id, host: host)
    end
  end
end
