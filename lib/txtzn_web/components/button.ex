defmodule TxtznWeb.Components.Button do
  @moduledoc """
  Documentation for `TxtznWeb.Button`
  """

  use Surface.Component

  prop full, :boolean

  prop kind, :string, values: ["primary", "secondary"], default: "secondary"

  prop type, :string, values: ["button", "reset", "submit"], default: "button"

  prop click, :event

  slot default, required: true

  def render(assigns) do
    ~H"""
    <button class={{ button_class(assigns) }} type={{ @type }} :on-click={{ @click }}>
      <slot/>
    </button>
    """
  end

  defp button_class(assigns) do
    Enum.reduce(assigns, "cursor-pointer", fn
      {:full, true}, class ->
        Enum.join(["w-full", class], " ")

      {:kind, "primary"}, class ->
        Enum.join(["px-4 py-2 bg-gray-300 hover:bg-gray-400", class], " ")

      _, class ->
        class
    end)
  end
end
