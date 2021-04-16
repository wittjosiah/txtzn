defmodule TxtznWeb.Flower do
  use TxtznWeb, :component

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
