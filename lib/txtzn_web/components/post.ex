defmodule TxtznWeb.Components.Post do
  @moduledoc """
  Documentation for `TxtznWeb.Components.Post`
  """

  use TxtznWeb, :surface_live_component

  alias CtznClient.{Session, Table}
  alias Phoenix.LiveView.Socket

  require Logger

  prop ctzn_session, :struct

  prop ctzn_ws_pid, :pid

  prop full, :boolean, default: false

  prop post, :map, required: true

  @impl true
  def handle_event("react", %{"reaction" => %{"reaction" => reaction}}, %Socket{} = socket) do
    handle_event("react", %{"reaction" => reaction}, socket)
  end

  def handle_event("react", %{"reaction" => reaction}, %Socket{} = socket) do
    %{ctzn_session: %Session{user_id: user_id}, ctzn_ws_pid: ws, post: post} = socket.assigns

    value = %{
      reaction: reaction,
      subject: %{dbUrl: post["url"], authorId: get_in(post, ["author", "userId"])}
    }

    case Table.create(ws, user_id, "ctzn.network/reaction", value) do
      {:ok, _} ->
        reactors =
          post
          |> get_in(["reactions", reaction])
          |> Kernel.||([])
          |> Enum.concat([user_id])

        post = put_in(post, ["reactions", reaction], reactors)
        {:noreply, assign(socket, :post, post)}

      {:error, error} ->
        metadata = [error: inspect(error), user_id: user_id]
        Logger.error("Failed to react to post (#{post["key"]})", metadata)
        {:noreply, socket}
    end
  end

  def handle_event("unreact", %{"reaction" => reaction}, %Socket{} = socket) do
    %{ctzn_session: %Session{user_id: user_id}, ctzn_ws_pid: ws, post: post} = socket.assigns
    value = "#{reaction}:#{post["url"]}"

    case Table.delete(ws, user_id, "ctzn.network/reaction", value) do
      {:ok, _} ->
        reactions = Map.get(post, "reactions")
        reactors = reactions |> Map.get(reaction) |> Enum.reject(&(&1 == user_id))

        post =
          if Enum.empty?(reactors) do
            Map.put(post, "reactions", Map.delete(reactions, reaction))
          else
            put_in(post, ["reactions", reaction], reactors)
          end

        {:noreply, assign(socket, :post, post)}

      {:error, error} ->
        metadata = [error: inspect(error), user_id: user_id]
        Logger.error("Failed to remove reaction from post (#{post["key"]})", metadata)
        {:noreply, socket}
    end
  end

  defp reaction_count(%{"reactions" => reactions}) do
    Enum.reduce(reactions, 0, fn {_, reactors}, count -> count + Enum.count(reactors) end)
  end

  defp render_extended(%{
         "value" => %{"extendedTextMimeType" => "text/html", "extendedText" => extended_text}
       }) do
    raw(extended_text)
  end

  defp render_extended(%{"value" => %{"extendedText" => extended_text}}) do
    Linkify.link_safe(extended_text, class: "text-moss-600 hover:underline")
  end

  defp post_url(%{"author" => %{"userId" => user_id}, "key" => key}) do
    Routes.post_path(Endpoint, :index, user_id, key)
  end
end
