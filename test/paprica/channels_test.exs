defmodule Paprica.ChannelsTest do
  use Paprica.DataCase

  alias Paprica.Channels

  describe "channels" do
    alias Paprica.Channels.Channel

    import Paprica.ChannelsFixtures

    @invalid_attrs %{mux_resource: nil, mux_live_stream_id: nil, slug: nil, stream_key: nil, mux_disconnected_at: nil, mux_live_playback_id: nil}

    test "list_channels/0 returns all channels" do
      channel = channel_fixture()
      assert Channels.list_channels() == [channel]
    end

    test "get_channel!/1 returns the channel with given id" do
      channel = channel_fixture()
      assert Channels.get_channel!(channel.id) == channel
    end

    test "create_channel/1 with valid data creates a channel" do
      valid_attrs = %{mux_resource: %{}, mux_live_stream_id: "some mux_live_stream_id", slug: "some slug", stream_key: "some stream_key", mux_disconnected_at: ~N[2023-08-30 01:17:00], mux_live_playback_id: "some mux_live_playback_id"}

      assert {:ok, %Channel{} = channel} = Channels.create_channel(valid_attrs)
      assert channel.mux_resource == %{}
      assert channel.mux_live_stream_id == "some mux_live_stream_id"
      assert channel.slug == "some slug"
      assert channel.stream_key == "some stream_key"
      assert channel.mux_disconnected_at == ~N[2023-08-30 01:17:00]
      assert channel.mux_live_playback_id == "some mux_live_playback_id"
    end

    test "create_channel/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Channels.create_channel(@invalid_attrs)
    end

    test "update_channel/2 with valid data updates the channel" do
      channel = channel_fixture()
      update_attrs = %{mux_resource: %{}, mux_live_stream_id: "some updated mux_live_stream_id", slug: "some updated slug", stream_key: "some updated stream_key", mux_disconnected_at: ~N[2023-08-31 01:17:00], mux_live_playback_id: "some updated mux_live_playback_id"}

      assert {:ok, %Channel{} = channel} = Channels.update_channel(channel, update_attrs)
      assert channel.mux_resource == %{}
      assert channel.mux_live_stream_id == "some updated mux_live_stream_id"
      assert channel.slug == "some updated slug"
      assert channel.stream_key == "some updated stream_key"
      assert channel.mux_disconnected_at == ~N[2023-08-31 01:17:00]
      assert channel.mux_live_playback_id == "some updated mux_live_playback_id"
    end

    test "update_channel/2 with invalid data returns error changeset" do
      channel = channel_fixture()
      assert {:error, %Ecto.Changeset{}} = Channels.update_channel(channel, @invalid_attrs)
      assert channel == Channels.get_channel!(channel.id)
    end

    test "delete_channel/1 deletes the channel" do
      channel = channel_fixture()
      assert {:ok, %Channel{}} = Channels.delete_channel(channel)
      assert_raise Ecto.NoResultsError, fn -> Channels.get_channel!(channel.id) end
    end

    test "change_channel/1 returns a channel changeset" do
      channel = channel_fixture()
      assert %Ecto.Changeset{} = Channels.change_channel(channel)
    end
  end
end
