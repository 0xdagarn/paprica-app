defmodule Paprica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PapricaWeb.Telemetry,
      # Start the Ecto repository
      Paprica.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Paprica.PubSub},
      # Start Finch
      {Finch, name: Paprica.Finch},
      # Start the Endpoint (http/https)
      PapricaWeb.Endpoint
      # Start a worker by calling: Paprica.Worker.start_link(arg)
      # {Paprica.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Paprica.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PapricaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
