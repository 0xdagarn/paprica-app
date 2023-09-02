defmodule PapricaWeb.StreamLive do
  use PapricaWeb, :live_view

  alias PapricaWeb.Presence

  alias Paprica.Channels
  alias Paprica.Messages
  alias Paprica.Messages.Message

  @topic "account:presences"

  def mount(%{"slug" => slug}, _session, socket) do
    if connected?(socket) do
      Messages.subscribe()
      Phoenix.PubSub.subscribe(Paprica.PubSub, @topic)
    end

    {:ok, socket} = case Channels.get_channel_by_slug(slug) do
      nil -> {:ok, redirect(socket, to: "/channel")}
      channel ->
        # message
        messages = Messages.list_messages()
        changeset = Messages.change_message(%Message{})
        form = to_form(changeset)
        socket =
          socket
          |> assign(:messages, messages)
          |> assign(:form, form)

        # presences
        presences = Presence.list(@topic)
        socket = assign(socket, :presences, presences)
        IO.inspect(presences, label: "presences!")

        # wallet
        socket = assign(socket, connected: false, address: nil)

        IO.inspect(channel.id, label: "channel-id")
        if connected?(socket), do: PapricaWeb.Endpoint.subscribe("channel-updated:#{channel.id}")

        IO.inspect(channel, label: "mounted-channel")

        if channel.stream_key do
          playback_url = Channels.playback_url_for_channel(channel)
          IO.inspect(playback_url, label: "mounted-playback_url")

          socket =
            socket
            |> assign(channel: channel)
            |> assign(slug: channel.slug)
            |> assign(status: channel.mux_resource["status"])
            |> assign(connected: channel.mux_resource["connected"])
            |> assign(stream_key: channel.stream_key)
            |> assign(playback_url: playback_url)
            |> assign(porcelain_process: "")
          IO.inspect("test", label: "assigned")

          {:ok, socket}
        else
          socket =
            socket
            |> assign(channel: channel)
            |> assign(playback_url: "")

          {:ok, socket}
        end
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <span id="metamask" phx-hook="Metamask">
      <%= if @connected do %>
        <span>My account</span>: <span><%= @address %></span>
      <% else %>
        <.button phx-click="connect-wallet">
          <span>Connect</span>
        </.button>
      <% end %>
    </span>
    <br/><br/>
    <div class="flex gap-4">
      <div class="flex-1">
        <div class="page-channel">
          <div class="channel-show-active">
            <div class="mt-5">
              <div class="row">
                <div class="col-sm-12 mux-video-cols">
                  <div class="mux-video-contain">
                    <div class="mux-tv-set">
                      <%= if @playback_url != "" do %>
                        <mux-player
                          stream-type="live"
                          playback-id={@playback_url}
                          metadata-video-title="Test video title"
                          metadata-viewer-user-id="user-id-007"
                        ></mux-player>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div>
          <div>Who's here?</div>
          <ul>
            <li :for={{address, _meta} <- @presences}>
              <span><%= address %></span>
            </li>
          </ul>
        </div>
      </div>
      <div class="flex-1">
        <div
          id="messages_container"
          phx-hook="ScrollToBottom"
          class="p-6 bg-white border rounded shadow max-h-96 overflow-y-auto"
        >
          <%= for message <- @messages do %>
            <b class="text-blue-500"><%= shorten_hex(message.address) %></b> <%= message.text %> <br />
          <% end %>
        </div>

        <.form
          id="message_form"
          for={@form}
          phx-submit="send"
        >
          <div class="flex">
            <div class="w-full">
              <.input
                field={@form[:text]}
                placeholder=""
                autocomplete="off"
                autofocus="true"
              />
              <%!-- <.input field={@form[:country]} placeholder="Come on!" autocomplete="off" />
              <.input field={@form[:address]} placeholder="Come on!" autocomplete="off" /> --%>
            </div>
            <div class="bg-red mt-2 ml-2">
              <.button>
                Send
              </.button>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  def handle_event("start-show", _, socket) do
    {:ok, live_stream, _env} = Mux.Video.LiveStreams.create(Mux.client(), %{
      playback_policy: "public",
      new_asset_settings: %{playback_policy: "public"}
    })
    IO.inspect(live_stream, label: "handle_event live_stream")
    stream_key = live_stream["stream_key"]
    live_stream_id = live_stream["id"]
    IO.inspect(stream_key, label: "handle_event stream_key")

    {:ok, channel} = Channels.update_channel(socket.assigns.channel, %{
      stream_key: stream_key,
      mux_resource: live_stream,
      mux_live_stream_id: live_stream_id
    })

    socket =
      socket
      |> assign(:channel, channel)
      |> assign(:porcelain_process, spawn_ffmpeg(stream_key))

    IO.inspect(socket, label: "handle_event socket")

    {:noreply, socket}
  end

  defp spawn_ffmpeg(key) do
    # Copied from https://github.com/MuxLabs/wocket/blob/master/server.js
    ffmpeg_args =
      ~w(-i - -c:v libx264 -preset veryfast -tune zerolatency -c:a aac -ar 44100 -b:a 64k -y -use_wallclock_as_timestamps 1 -async 1 -bufsize 1000 -f flv)

    Porcelain.spawn("ffmpeg", ffmpeg_args ++ ["rtmps://global-live.mux.com/app/#{key}"])
  end

  @impl true
  def handle_event("video_data", %{"data" => "data:video/x-matroska;codecs=avc1,opus;base64," <> data}, socket) do
    Porcelain.Process.send_input(socket.assigns.porcelain_process, Base.decode64!(data))

    {:noreply, socket}
  end

  def handle_event("send", %{"message" => message_param}, socket) do
    # IO.inspect(message_param, label: "message_param")

    message = message_param
      |> Map.put("address", socket.assigns.address)
      |> Map.put("country", "KOR")
    IO.inspect(message, label: "message")

    case Messages.create_message(message) do
      {:ok, _message} ->
        changeset = Messages.change_message(%Message{})
        IO.inspect(changeset, label: "changeset")

        {:noreply, assign(socket, form: to_form(changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_info({:message_created, message}, socket) do
    # fn messages -> [message | messages] end
    # fn messages -> messages ++ [message] end
    # he first function adds the message at the start of the messages list,
    # while the second function adds the message at the end of the messages list.
    # The first function is more efficient, especially for long lists.

    # recommend using Hooks in case long lists. https://chat.openai.com/share/219e0df1-3469-4976-bb5b-36634250af8d
    socket =
      update(socket,
        :messages,
        fn messages -> messages ++ [message] end
      )

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    IO.inspect(diff, label: "diff-is-diff")
    socket =
      socket
      |> remove_presences(diff.leaves)
      |> add_presences(diff.joins)

    {:noreply, socket}
  end

  defp remove_presences(socket, leaves) do
    user_ids = Enum.map(leaves, fn {user_id, _} -> user_id end)

    presences = Map.drop(socket.assigns.presences, user_ids)

    assign(socket, :presences, presences)
  end

  defp add_presences(socket, joins) do
    presences = Map.merge(socket.assigns.presences, simple_presence_map(joins))
    assign(socket, :presences, presences)
  end

  def handle_event("wallet-connected", %{"address" => address}, socket) do
    IO.inspect(address, label: "wallet-connected")

    {:ok, _} =
      Presence.track(self(), @topic, address, %{
        address: address
        # is_playing: false
      })

      IO.inspect(address, label: "wallet-connected2")

    presences = Presence.list(@topic)
    socket = assign(socket, :presences, presences)

    IO.inspect(presences, label: "wallet-presences")

    message = Map.new()
      |> Map.put("text", "Welcome, " <> address)
    Messages.create_message(message)

    {:noreply, assign(socket, connected: true, address: address)}
  end

  def handle_event("connect-wallet", _params, socket) do
    {:noreply, push_event(socket, "connect-wallet", %{})}
  end

  def simple_presence_map(presences) do
    Enum.into(presences, %{}, fn {user_id, %{metas: [meta | _]}} ->
      {user_id, meta}
    end)
  end

  def shorten_hex(hex) do
    case hex do
      nil -> ""
      "" -> ""
      _ -> String.slice(hex, 0, 5) <> "..." <> String.slice(hex, -6, 4) <> ": "
    end
  end
end
