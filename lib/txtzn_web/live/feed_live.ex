defmodule TxtznWeb.FeedLive do
  use Surface.LiveView

  import TxtznWeb.LiveHelpers

  alias CtznClient.View
  alias Phoenix.LiveView.Socket
  alias Surface.Components.{Link, LiveRedirect}
  alias Txtzn.CtznCache
  alias TxtznWeb.Components.Button
  alias TxtznWeb.Router.Helpers, as: Routes

  require Logger

  @default_opts %{limit: 15, reverse: true}

  @impl true
  def handle_event("load-more", _, %Socket{} = socket) do
    send(self(), :load_more)
    {:noreply, assign(socket, :loading, true)}
  end

  def handle_info(:load_more, %Socket{assigns: %{next_page: next_page}} = socket) do
    socket =
      socket
      |> assign_feed(Map.put(@default_opts, :lt, next_page))
      |> assign(:loading, false)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, %Socket{} = socket) do
    opts = if lt = params["lt"], do: Map.put(@default_opts, :lt, lt), else: @default_opts
    {:noreply, assign_feed(socket, opts)}
  end

  @impl true
  def mount(_params, session, %Socket{} = socket) do
    with %Socket{} = socket <- assign_defaults(socket, session) do
      socket = assign(socket, loading: false, page_title: "Feed")
      {:ok, socket, temporary_assigns: [feed: []]}
    end
  end

  defp assign_feed(%Socket{assigns: %{ctzn_ws_pid: ws}} = socket, opts) do
    case View.get(ws, "ctzn.network/feed-view", opts) do
      {:ok, %{"feed" => feed}} ->
        %{"key" => next_page} = List.last(feed)

        socket
        |> assign(:feed, process_feed(feed, ws))
        |> assign(:next_page, next_page)

      {:error, error} ->
        metadata = [client_id: socket.assigns.client_id, error: inspect(error)]
        Logger.error("Failed to fetch feed", metadata)
        put_flash(socket, :error, "Failed to fetch feed")
    end
  end

  defp process_author(post, feed) do
    with %{"author" => author_key} when is_binary(author_key) <- post,
         [index_str, _] <- author_key |> String.split("~") |> Enum.drop(3),
         {index, _} <- Integer.parse(index_str),
         %{} = author <- feed |> Enum.at(index) |> Map.get("author") do
      %{post | "author" => author}
    else
      _ -> post
    end
  end

  defp process_community(post, ws) when is_pid(ws) do
    with community_id when is_binary(community_id) <-
           get_in(post, ["value", "community", "userId"]),
         {:ok, community_profile} <- CtznCache.get_profile(community_id, ws) do
      put_in(post, ["value", "community"], community_profile)
    else
      _ -> post
    end
  end

  defp process_content(%{"value" => %{"text" => text}} = post) do
    text = Linkify.link_safe(text, class: "text-blue-600 hover:underline")
    put_in(post, ["value", "text"], text)
  end

  defp process_feed(feed, ws), do: Enum.map(feed, &process_post(&1, feed, ws))

  defp process_post(post, feed, ws) do
    post
    |> process_author(feed)
    |> process_community(ws)
    |> process_content()
    |> process_time()
  end

  defp process_time(post) do
    with time_str when is_binary(time_str) <- get_in(post, ["value", "createdAt"]),
         {:ok, time} <- Timex.parse(time_str, "{ISO:Extended:Z}") do
      put_in(post, ["value", "createdAgo"], Timex.from_now(time))
    else
      _ -> post
    end
  end
end
