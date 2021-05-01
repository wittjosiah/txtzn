defmodule TxtznWeb.ProfileLive do
  use TxtznWeb, :live_view

  import TxtznWeb.LiveHelpers

  alias Phoenix.LiveView.Socket

  require Logger

  @impl true
  def mount(_params, session, %Socket{} = socket) do
    with %Socket{} = socket <- assign_defaults(socket, session) do
      {:ok, assign(socket, :page_title, "Profile")}
    end
  end
end
