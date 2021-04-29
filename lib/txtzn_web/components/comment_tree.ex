defmodule TxtznWeb.Components.CommentTree do
  @moduledoc """
  Documentation for `TxtznWeb.Components.CommentTree`
  """

  use TxtznWeb, :live_component

  alias CtznClient.{Session, Table}
  alias Phoenix.LiveView.Socket

  require Logger

  def handle_event("comment", %{"comment" => form}, %Socket{} = socket) do
    %{ctzn_session: %Session{user_id: user_id}, ctzn_ws_pid: ws} = socket.assigns

    community =
      with true <- is_binary(form["community"]),
           [community_id, community_url] <- String.split(form["community"], "<>") do
        %{dbUrl: community_url, user_id: community_id}
      else
        _ -> nil
      end

    [root_author, root_url] = String.split(form["root"], "<>")
    [parent_author, parent_url] = String.split(form["parent"], "<>")
    root = %{authorId: root_author, dbUrl: root_url}
    parent = %{authorId: parent_author, dbUrl: parent_url}
    reply = %{root: root, parent: parent}
    value = %{reply: reply, text: form["text"]}
    value = if community, do: Map.put(value, :community, community), else: value

    case Table.create(ws, user_id, "ctzn.network/comment", value) do
      {:ok, %{"key" => _key, "url" => _url}} ->
        {:noreply, socket}

      {:error, error} ->
        metadata = [error: inspect(error), user_id: user_id]
        Logger.error("Failed to create comment", metadata)
        {:noreply, socket}
    end
  end

  def mount(socket) do
    socket = Surface.init(socket)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <div :for={{ comment <- @comments }} class="border-l-2 border-peach-300 px-3 pt-1 my-3">
        <div class="flex justify-between">
          <p class="w-2/3 font-bold overflow-ellipsis overflow-hidden whitespace-nowrap">
            <LiveRedirect
              opts={{ title: get_in(comment, ["author", "userId"]) }}
              to="#profileTODO"
            >
              {{ get_in(comment, ["author", "displayName"]) }}
            </LiveRedirect>
          </p>
          <LiveRedirect
            class="w-1/3 text-right text-sm text-gray-500"
            opts={{ title: get_in(comment, ["value", "createdAt"]) }}
            to="#commentTODO"
          >
            {{ get_in(comment, ["value", "createdAgo"]) }}
          </LiveRedirect>
        </div>

        <p id={{ comment["key"] }}>
          {{ get_in(comment, ["value", "text"]) }}
        </p>

        <div class="flex items-center my-1">
          <Reaction
            :for={{ {reaction, reactors} <- comment["reactions"] }}
            reaction={{ reaction }}
            reactors={{ reactors }}
            target={{ "#" <> comment["key"] }}
            user_id={{ @ctzn_session.user_id }}
          />
        </div>

        <label for="react-{{ comment["key"] }}" class="cursor-pointer">
          React
        </label>

        <label for="reply-{{ comment["key"] }}" class="cursor-pointer">
          Reply
        </label>

        <input class="hidden" id="react-{{ comment["key"] }}" name="comment-{{ comment["key"] }}-actions" type="radio"/>
        <div class="hidden toggle">
          <Form action="/react" for={{ :reaction }} method="POST" opts={{ class: "flex" }} submit="react">
            <Field class="flex-grow" name="reaction">
              <TextInput class="p-1 w-full border border-peach-300 focus:border-peach-600 outline-none"/>
            </Field>
            <Button class="ml-2" kind="secondary" type="submit">
              Add
            </Button>
          </Form>
        </div>

        <input class="hidden" id="reply-{{ comment["key"] }}" name="comment-{{ comment["key"] }}-actions" type="radio"/>
        <div class="hidden toggle">
          <Form
            action="/comment"
            for={{ :comment }}
            method="POST"
            opts={{ "phx-target": "##{comment["key"]}" }}
            submit="comment"
          >
            <HiddenInput field="community" value={{ community_value(comment) }}/>
            <HiddenInput field="parent" value={{ parent_value(comment) }}/>
            <HiddenInput field="root" value={{ root_value(comment) }}/>
            <Field class="flex flex-col flex-wrap mb-2" name="text">
              <TextArea
                class="flex-grow h-screen-1/3 p-2 border border-peach-300 focus:border-peach-600 outline-none resize-none"
                field="text"
              />
            </Field>
            <div class="flex justify-end">
              <Button kind="secondary" type="submit">
                Comment
              </Button>
            </div>
          </Form>
        </div>

        <div :if={{ comment["replies"] }}>
          {{ live_component @socket, __MODULE__, Map.merge(assigns, %{id: "#{comment["key"]}-replies", comments: comment["replies"]}) }}
        </div>
      </div>
    """
  end

  defp community_value(%{"value" => %{"community" => %{"dbUrl" => url, "userId" => user_id}}}) do
    "#{user_id}<>#{url}"
  end

  defp community_value(_), do: nil

  defp parent_value(%{"author" => %{"userId" => user_id}, "url" => url}) do
    "#{user_id}<>#{url}"
  end

  defp root_value(%{
         "value" => %{"reply" => %{"root" => %{"authorId" => user_id, "dbUrl" => url}}}
       }) do
    "#{user_id}<>#{url}"
  end
end
