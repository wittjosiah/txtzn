defmodule TxtznWeb.MediaLive do
  use TxtznWeb, :live_view

  import TxtznWeb.LiveHelpers

  alias CtznClient.View
  alias Phoenix.LiveView.Socket
  alias TxtznWeb.Endpoint

  require Logger

  @impl true
  def handle_params(%{"key" => key, "user_id" => user_id}, _uri, %Socket{} = socket) do
    {:noreply, assign_post(socket, user_id, key)}
  end

  @impl true
  def mount(_params, session, %Socket{} = socket) do
    with %Socket{} = socket <- assign_defaults(socket, session) do
      {:ok, assign(socket, :page_title, "Media")}
    end
  end

  defp assign_post(%Socket{assigns: %{ctzn_ws_pid: ws}} = socket, user_id, key) do
    case View.get(ws, "ctzn.network/post-view", [user_id, key]) do
      {:ok, %{"author" => %{"displayName" => name, "userId" => user_id}} = result} ->
        socket
        |> assign(:author_id, user_id)
        |> assign(:post, result)
        |> assign(:page_title, "Media from #{name}")

      {:error, error} ->
        metadata = [client_id: socket.assigns.client_id, error: inspect(error)]
        Logger.error("Failed to fetch post", metadata)
        put_flash(socket, :error, "Failed to fetch post")
    end
  end

  defp media_url(user_id, %{"blobs" => %{"original" => %{"blobName" => blob}}}) do
    [_, host] = String.split(user_id, "@")
    "https://#{host}/.view/ctzn.network/blob-view/#{user_id}/#{blob}"
  end

  defp post_url(%{"author" => %{"userId" => user_id}, "key" => key}) do
    Routes.post_path(Endpoint, :index, user_id, key)
  end
end
