defmodule Paprica.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :mux_resource, :map
      add :mux_live_stream_id, :string
      add :slug, :string
      add :stream_key, :string
      add :mux_disconnected_at, :naive_datetime
      add :mux_live_playback_id, :string

      timestamps()
    end
  end
end
