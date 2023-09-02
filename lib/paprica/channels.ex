defmodule Paprica.Channels do
  @moduledoc """
  The Channels context.
  """

  import Ecto.Query, warn: false
  alias Paprica.Repo

  alias Paprica.Channels.Channel

  @doc """
  Returns the list of channels.

  ## Examples

      iex> list_channels()
      [%Channel{}, ...]

  """
  def list_channels do
    Repo.all(Channel)
  end

  def find_by_mux_live_stream_id(live_stream_id) do
    Repo.get_by(Channel, %{mux_live_stream_id: live_stream_id})
  end

  @doc """
  Gets a single channel.

  Raises `Ecto.NoResultsError` if the Channel does not exist.

  ## Examples

      iex> get_channel!(123)
      %Channel{}

      iex> get_channel!(456)
      ** (Ecto.NoResultsError)

  """
  def get_channel!(id), do: Repo.get!(Channel, id)

  def get_channel_by_slug(slug) do
    Repo.get_by(Channel, %{slug: slug})
  end

  @doc """
  Creates a channel.

  ## Examples

      iex> create_channel(%{field: value})
      {:ok, %Channel{}}

      iex> create_channel(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_channel(attrs \\ %{}) do
    %Channel{}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a channel.

  ## Examples

      iex> update_channel(channel, %{field: new_value})
      {:ok, %Channel{}}

      iex> update_channel(channel, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_channel(%Channel{} = channel, attrs) do
    channel
    |> Channel.changeset(attrs)
    |> Repo.update()
    |> notify_subs()
  end

  def notify_subs({:ok, channel}) do
    Phoenix.PubSub.broadcast(Paprica.PubSub, "channel-updated:#{channel.id}", channel)
    {:ok, channel}
  end

  def update_from_mux_webhook(%Channel{} = channel, params) do
    mux_resource = params["data"]
    attrs = %{mux_resource: mux_resource}

    attrs =
      if params["type"] == "video.live_stream.disconnected" do
        Map.put(attrs, :mux_disconnected_at, NaiveDateTime.from_iso8601!(params["created_at"]))
      else
        attrs
      end

    attrs =
      if mux_resource["playback_ids"] do
        playback_id = List.first(mux_resource["playback_ids"])["id"]
        Map.put(attrs, :mux_live_playback_id, playback_id)
      else
        attrs
      end

    IO.inspect(attrs, label: "update_from_mux_webhook")
    update_channel(channel, attrs)
  end

  def playback_url_for_channel(%Channel{} = channel) do
    IO.inspect(channel, label: "playback_url_for_channel")

    case channel.mux_live_playback_id do
      nil ->
        ""

      playback_id ->
        # "https://stream.mux.com/#{playback_id}.m3u8"
        playback_id
    end

    # case channel.mux_resource["status"] do
    #   "idle" ->
    #     case channel.mux_live_playback_id do
    #       nl ->
    #         nil

    #       playback_id ->
    #         "https://stream.mux.com/#{playback_id}.m3u8"
    #     end

    #   _ ->
    #     nil
    # end
  end

  @doc """
  Deletes a channel.

  ## Examples

      iex> delete_channel(channel)
      {:ok, %Channel{}}

      iex> delete_channel(channel)
      {:error, %Ecto.Changeset{}}

  """
  def delete_channel(%Channel{} = channel) do
    Repo.delete(channel)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking channel changes.

  ## Examples

      iex> change_channel(channel)
      %Ecto.Changeset{data: %Channel{}}

  """
  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end
end
