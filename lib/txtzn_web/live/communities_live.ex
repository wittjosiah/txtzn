defmodule TxtznWeb.CommunitiesLive do
  use TxtznWeb, :live_view

  import TxtznWeb.LiveHelpers

  alias CtznClient.{Session, Table}
  alias Phoenix.LiveView.Socket
  alias Txtzn.CtznCache

  require Logger

  @static_communities [
    %{
      user_id: "alphatesters@ctzn.one",
      display_name: "CTZN Alpha Testers",
      description: "Find other CTZN alpha users and talk about what\'s going on with the network."
    },
    %{
      user_id: "welcome@ctzn.one",
      display_name: "Welcome to CTZN",
      description: "A place for new users to ask questions!"
    },
    %{
      user_id: "ktzns@ctzn.one",
      display_name: "KTZNs",
      description: "A community for cat lovers."
    },
    %{
      user_id: "quotes@ctzn.one",
      display_name: "Quotes",
      description: "Share the wisdom, or lack thereof."
    },
    %{
      user_id: "gameboard@ctzn.one",
      display_name: "Boardgames",
      description: "A place to share what you\'ve been playing."
    },
    %{
      user_id: "P2P@ctzn.one",
      display_name: "P2P",
      description: "A place to chat about P2P, Federated, and Decentralised Systems!"
    },
    %{
      user_id: "mlai@ctzn.one",
      display_name: "Machine Learning & artificial intelligence",
      description: "A space for ML & AI discussions."
    },
    %{
      user_id: "rustaceans@ctzn.one",
      display_name: "Rustaceans",
      description:
        "Rustaceans are people who use Rust, contribute to Rust, or are interested in the development of Rust."
    },
    %{
      user_id: "python@ctzn.one",
      display_name: "Python",
      description: "Python programming language"
    },
    %{
      user_id: "GeminiEnthusiasts@ctzn.one",
      display_name: "Gemini Protocol Enthusiasts",
      description: "Community for people who love the Gemeni protocol."
    },
    %{
      user_id: "sports@ctzn.one",
      display_name: "Sports",
      description: "A place all around sports."
    },
    %{
      user_id: "Hamradio@ctzn.one",
      display_name: "Hamradio",
      description: "Hamradio Community"
    }
  ]

  @impl true
  def mount(_params, session, %Socket{} = socket) do
    with %Socket{} = socket <- assign_defaults(socket, session) do
      socket =
        socket
        |> assign_communities()
        |> assign(:page_title, "Communities")

      {:ok, socket}
    end
  end

  defp assign_communities(%Socket{} = socket) do
    %{ctzn_session: %Session{user_id: user_id}, ctzn_ws_pid: ws} = socket.assigns

    case Table.list(ws, user_id, "ctzn.network/community-membership") do
      {:ok, %{"entries" => entries}} ->
        {communities, suggested_communities} = parse_communities(entries, ws)

        socket
        |> assign(:communities, communities)
        |> assign(:suggested_communities, suggested_communities)

      {:error, error} ->
        metadata = [client_id: socket.assigns.client_id, error: inspect(error)]
        Logger.error("Failed to fetch communities", metadata)

        socket
        |> assign(:communities, [])
        |> assign(:suggested_communities, @static_communities)
        |> put_flash(:error, "Failed to fetch your communities")
    end
  end

  defp parse_communities(communities, ws) do
    communities =
      communities
      |> Enum.map(&get_in(&1, ["value", "community", "userId"]))
      |> Enum.map(&CtznCache.get_profile(&1, ws))
      |> Enum.map(fn
        {:ok, community} ->
          %{
            description: get_in(community, ["value", "description"]),
            display_name: get_in(community, ["value", "displayName"]),
            user_id: community["userId"]
          }

        _ ->
          nil
      end)
      |> Enum.reject(&is_nil/1)

    suggested_communities =
      Enum.reject(@static_communities, fn static_community ->
        Enum.any?(communities, &(&1.user_id == static_community.user_id))
      end)

    {communities, suggested_communities}
  end
end
