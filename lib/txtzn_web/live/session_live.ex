defmodule TxtznWeb.SessionLive do
  use Surface.LiveView

  alias CtznClient.Session
  alias Surface.Components.Link
  alias TxtznWeb.Components.{SignInForm}
  alias TxtznWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, %{"ctzn_session" => %Session{}}, socket) do
    {:ok, push_redirect(socket, to: Routes.feed_path(socket, :index))}
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Sign In")}
  end
end
