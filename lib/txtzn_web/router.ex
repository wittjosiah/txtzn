defmodule TxtznWeb.Router do
  use TxtznWeb, :router

  alias CtznClient.{Accounts, Session}
  alias Plug.Conn
  alias Txtzn.CtznHelpers

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
    post "/comment", CommentController, :comment
    live "/feed", FeedLive, :index
    live "/feed/:key", FeedLive, :index
    post "/post", PostController, :post
    post "/react", ReactionController, :react
    live "/signin", SessionLive, :index
    post "/signin", SessionController, :sign_in
    live "/:user_id/ctzn.network/post/:key", PostLive, :index
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
    with %Session{session_id: session_id} = session <- get_session(conn, :ctzn_session),
         {:ok, pid} <- CtznHelpers.lookup_or_start_ws(id, session) do
      Accounts.resume_session(pid, session_id)
      assign(conn, :ctzn_ws_pid, pid)
    else
      _ -> conn
    end
  end
end
