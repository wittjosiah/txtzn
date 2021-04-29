defmodule TxtznWeb.Components.Button do
  @moduledoc """
  Documentation for `TxtznWeb.Button`
  """

  use TxtznWeb, :surface_component

  prop class, :css_class

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
      {:class, custom_class}, class ->
        Enum.join([custom_class, class], " ")

      {:full, true}, class ->
        Enum.join(["w-full", class], " ")

      {:kind, "primary"}, class ->
        Enum.join(["px-4 py-2 bg-moss-300 hover:bg-moss-400", class], " ")

      {:kind, "secondary"}, class ->
        Enum.join(["px-2 py-1 border border-moss-400 bg-moss-100 hover:bg-moss-200", class], " ")

      _, class ->
        class
    end)
  end
end
