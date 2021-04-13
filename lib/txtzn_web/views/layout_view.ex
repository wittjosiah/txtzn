defmodule TxtznWeb.LayoutView do
  use TxtznWeb, :view

  import Plug.Conn, only: [get_session: 2]

  alias CtznClient.Session
end
