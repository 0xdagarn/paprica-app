defmodule Paprica.ChannelsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Paprica.Channels` context.
  """

  @doc """
  Generate a channel.
  """
  def channel_fixture(attrs \\ %{}) do
    {:ok, channel} =
      attrs
      |> Enum.into(%{
        mux_resource: %{},
        mux_live_stream_id: "some mux_live_stream_id",
        slug: "some slug",
        stream_key: "some stream_key",
        mux_disconnected_at: ~N[2023-08-30 01:17:00],
        mux_live_playback_id: "some mux_live_playback_id"
      })
      |> Paprica.Channels.create_channel()

    channel
  end
end
