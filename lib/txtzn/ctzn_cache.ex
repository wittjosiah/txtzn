defmodule Txtzn.CtznCache do
  @moduledoc """
  Documentation for `Txtzn.CtznCache`.
  """

  alias CtznClient.View

  @cache :ctzn_cache

  def get_profile(user_id, ws) do
    key = "profile/#{user_id}"

    ConCache.fetch_or_store(@cache, key, fn ->
      View.get(ws, "ctzn.network/profile-view", user_id)
    end)
  end
end
