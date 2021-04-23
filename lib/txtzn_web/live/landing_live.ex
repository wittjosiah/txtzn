defmodule TxtznWeb.LandingLive do
  use TxtznWeb, :live_view

  alias CtznClient.Session

  @impl true
  def mount(_params, %{"ctzn_session" => %Session{}}, socket) do
    {:ok, push_redirect(socket, to: Routes.feed_path(socket, :index))}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Welcome")}
  end
end
