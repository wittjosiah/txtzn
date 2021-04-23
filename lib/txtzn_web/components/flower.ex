defmodule TxtznWeb.Components.Flower do
  use TxtznWeb, :surface_component

  def render(assigns) do
    ~H"""
    <#Raw>
      <pre class="leading-5 text-xl">
         _,-._
        / \_/ \
        >-(_)-<
        \_/ \_/
          `-'
      </pre>
    </#Raw>
    """
  end
end
