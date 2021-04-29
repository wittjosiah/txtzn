defmodule TxtznWeb.Components.Reaction do
  @moduledoc """
  Documentation for `TxtznWeb.Components.Reaction`
  """

  use TxtznWeb, :surface_component

  prop reaction, :string, required: true

  prop reactors, :list, required: true

  prop target, :string

  prop user_id, :string

  def render(assigns) do
    ~H"""
    <button
      :on-click={{ event(@reactors, @user_id) }}
      class={{ class(@reactors, @user_id) }}
      phx-target={{ @target }}
      phx-value-reaction={{ @reaction }}
    >
      <span class="py-0.5">{{ @reaction }}</span>
      <span
        class="border-l border-{{ color(@reactors, @user_id) }}-500 ml-1 pl-1 py-0.5"
      >
        {{ Enum.count(@reactors) }}
      </span>
    </button>
    """
  end

  defp class(reactors, user_id) do
    color = color(reactors, user_id)
    "bg-#{color}-300 hover:bg-#{color}-400 rounded mr-1 px-1 text-xs flex"
  end

  defp color(reactors, user_id) do
    if reacted?(reactors, user_id), do: "moss", else: "peach"
  end

  defp event(reactors, user_id) do
    if reacted?(reactors, user_id), do: "unreact", else: "react"
  end

  defp reacted?(reactors, user_id), do: user_id in reactors
end
