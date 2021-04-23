defmodule TxtznWeb.Components.Mushroom do
  use TxtznWeb, :surface_component

  def render(assigns) do
    ~H"""
    <#Raw>
      <pre class="leading-3 text-xs">
                             .-'~~~-.
                           .'o  oOOOo`.
                          :~~~-.oOo   o`.
                           `. \ ~-.  oOOo.
                             `.; / ~.  OO:
                             .'  ;-- `.o.'
                            ,'  ; ~~--'~
                            ;  ;
      _______\|/__________\\;_\\//___\|/________
      </pre>
    </#Raw>
    """
  end
end
