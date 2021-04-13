defmodule Txtzn.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      TxtznWeb.Telemetry,
      {Phoenix.PubSub, name: Txtzn.PubSub},
      TxtznWeb.Endpoint,
      {Registry, keys: :unique, name: Registry.CtznClient},
      CtznClient.Supervisor,
      {ConCache,
       [
         global_ttl: :timer.hours(24),
         name: :ctzn_cache,
         touch_on_read: true,
         ttl_check_interval: :timer.hours(1)
       ]}
    ]

    opts = [strategy: :one_for_one, name: Txtzn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    TxtznWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
