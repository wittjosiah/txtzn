defmodule TxtznWeb.Components.PostSummary do
  @moduledoc """
  Documentation for `TxtznWeb.Components.PostSummary`
  """

  use TxtznWeb, :component

  prop post, :map, required: true

  defp post_url(%{"author" => %{"userId" => user_id}, "key" => key}) do
    Routes.post_path(Endpoint, :index, user_id, key)
  end
end
