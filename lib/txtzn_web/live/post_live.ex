defmodule TxtznWeb.PostLive do
  use Surface.LiveView

  import TxtznWeb.LiveHelpers

  alias CtznClient.View
  alias Phoenix.LiveView.Socket
  alias Surface.Components.{Link, LiveRedirect}
  alias Txtzn.CtznCache
  alias TxtznWeb.Components.Button
  alias TxtznWeb.Router.Helpers, as: Routes

  require Logger

  @impl true
  def handle_params(%{"key" => key, "user_id" => user_id}, _uri, %Socket{} = socket) do
    socket =
      socket
      |> assign_post(user_id, key)
      |> assign_thread()

    {:noreply, socket}
  end

  @impl true
  def mount(_params, session, %Socket{} = socket) do
    with %Socket{} = socket <- assign_defaults(socket, session) do
      {:ok, assign(socket, :page_title, "Post")}
    end
  end

  defp assign_post(%Socket{assigns: %{ctzn_ws_pid: ws}} = socket, user_id, key) do
    case View.get(ws, "ctzn.network/post-view", [user_id, key]) do
      {:ok, %{"author" => %{"displayName" => name}} = result} ->
        socket
        |> assign(:post, result)
        |> assign(:page_title, "Post by #{name}")

      {:error, error} ->
        metadata = [client_id: socket.assigns.client_id, error: inspect(error)]
        Logger.error("Failed to fetch post", metadata)
        put_flash(socket, :error, "Failed to fetch post")
    end
  end

  defp assign_thread(%Socket{assigns: %{ctzn_ws_pid: ws, post: %{"url" => url}}} = socket) do
    case View.get(ws, "ctzn.network/thread-view", [url]) do
      {:ok, %{"comments" => comments}} ->
        assign(socket, :comments, comments)

      {:error, error} ->
        metadata = [client_id: socket.assigns.client_id, error: inspect(error)]
        Logger.error("Failed to fetch thread", metadata)
        put_flash(socket, :error, "Failed to fetch thread")
    end
  end

  defp assign_thread(%Socket{} = socket), do: socket
end
