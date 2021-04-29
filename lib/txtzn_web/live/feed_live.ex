defmodule TxtznWeb.FeedLive do
  use TxtznWeb, :live_view

  import TxtznWeb.LiveHelpers

  alias CtznClient.{Session, View, Table}
  alias Phoenix.LiveView.Socket
  alias Txtzn.CtznCache
  alias TxtznWeb.Components.Post

  require Logger

  @default_opts %{limit: 15, reverse: true}

  @impl true
  def handle_event(
        "composer-toggle",
        _,
        %Socket{assigns: %{composer_open: composer_open}} = socket
      ) do
    {:noreply, assign(socket, :composer_open, !composer_open)}
  end

  def handle_event("load-from", %{"key" => key}, %Socket{} = socket) do
    {:noreply, push_patch(socket, to: Routes.feed_path(socket, :index, key), replace: true)}
  end

  def handle_event("load-from", _, %Socket{} = socket) do
    {:noreply, push_patch(socket, to: Routes.feed_path(socket, :index), replace: true)}
  end

  def handle_event("load-more", _, %Socket{} = socket) do
    send(self(), :load_more)
    {:noreply, assign(socket, :loading, true)}
  end

  def handle_event("post", %{"post" => form}, %Socket{} = socket) do
    %{ctzn_session: %Session{user_id: user_id}, ctzn_ws_pid: ws} = socket.assigns
    value = Map.put(form, "createdAt", DateTime.to_string(DateTime.utc_now()))

    case Table.create(ws, user_id, "ctzn.network/post", value) do
      {:ok, %{"key" => _key, "url" => _url}} ->
        {:noreply, socket}

      {:error, error} ->
        metadata = [error: inspect(error), user_id: user_id]
        Logger.error("Failed to create post (UserId=#{user_id})", metadata)
        {:noreply, socket}
    end
  end

  def handle_event("post-change", %{"post" => form}, %Socket{} = socket) do
    {:noreply, assign(socket, :composer, form)}
  end

  @impl true
  def handle_info(:load_more, %Socket{assigns: %{next_page: next_page}} = socket) do
    socket =
      socket
      |> assign_feed(Map.put(@default_opts, :lt, next_page))
      |> assign(:loading, false)

    {:noreply, socket}
  end

  def handle_info({:load_until, key}, %Socket{assigns: %{ctzn_ws_pid: ws}} = socket) do
    backfeed =
      socket
      |> fetch_backfeed(key)
      |> process_feed(ws)

    {:noreply, assign(socket, :backfeed, backfeed)}
  end

  @impl true
  def handle_params(%{"key" => key}, _, %Socket{assigns: %{initialized: false}} = socket) do
    socket =
      socket
      |> assign(:initialized, true)
      |> assign_feed(Map.put(@default_opts, :lt, key))

    send(self(), {:load_until, key})

    {:noreply, socket}
  end

  def handle_params(_, _, %Socket{assigns: %{initialized: false}} = socket) do
    socket =
      socket
      |> assign(:initialized, true)
      |> assign_feed(@default_opts)

    {:noreply, socket}
  end

  def handle_params(_, _, %Socket{} = socket) do
    {:noreply, socket}
  end

  @impl true
  def mount(_params, session, %Socket{} = socket) do
    with %Socket{} = socket <- assign_defaults(socket, session) do
      socket =
        assign(socket,
          composer: %{"text" => "", "extendedText" => ""},
          composer_open: false,
          initialized: false,
          loading: false,
          page_title: "Feed"
        )

      {:ok, socket, temporary_assigns: [backfeed: [], feed: []]}
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

  defp fetch_backfeed(%Socket{} = socket, until_key, next_key \\ nil, backfeed \\ []) do
    %{client_id: client_id, ctzn_ws_pid: ws} = socket.assigns
    backfeed_opts = Map.put(@default_opts, :limit, 5)
    opts = if next_key, do: Map.put(backfeed_opts, :lt, next_key), else: backfeed_opts

    feed =
      case View.get(ws, "ctzn.network/feed-view", opts) do
        {:ok, %{"feed" => feed}} ->
          feed

        {:error, error} ->
          metadata = [client_id: client_id, error: inspect(error)]
          Logger.error("Failed to fetch backfeed", metadata)
          []
      end

    until_feed =
      if key_index = Enum.find_index(feed, fn %{"key" => key} -> key == until_key end) do
        Enum.take(feed, key_index + 1)
      else
        feed
      end

    backfeed = Enum.concat(backfeed, until_feed)

    if Enum.count(feed) > Enum.count(until_feed) or Enum.empty?(until_feed) do
      backfeed
    else
      %{"key" => next_key} = List.last(feed)
      fetch_backfeed(socket, until_key, next_key, backfeed)
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
    text = Linkify.link_safe(text, class: "text-moss-600 hover:underline")
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

  defp render_backfeed?(false, _), do: false
  defp render_backfeed?(true, backfeed), do: !Enum.empty?(backfeed)
end
