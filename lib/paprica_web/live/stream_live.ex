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
        socket = assign(socket, connected: false, address: nil, chainId: nil, balance: nil)

        socket = assign(socket, supporting: "")

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
            |> assign(selectedAddress: "")
            |> assign(tokenBalance: "")
            |> assign(tokenURI: "")
          IO.inspect("test", label: "assigned")

          {:ok, socket}
        else
          socket =
            socket
            |> assign(channel: channel)
            |> assign(socket, supporting: "")
            |> assign(playback_url: "")
            |> assign(selectedAddress: "")
            |> assign(tokenBalance: "")
            |> assign(tokenURI: "")

          {:ok, socket}
        end
      end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.modal id="account-modal">
      <div class="flex gap-8">
        <div class="flex-1">
          <img src={@tokenURI}/>
        </div>
        <div class="flex-1 mt-40">
          <div>
            <span>- token-bound account</span>
            <span>: <%= shorten_hex_not_colon("0x9f3E42eCBC13662966e104f8862D0588471A3Ef6") %></span>
          </div>
          <div>
            <span>- balance</span>
            <span>: <%= @tokenBalance %> tokens</span>
          </div>
          <div class="flex flex-col justify-between">
            <div>
              <hr class="my-4" />
            </div>
            <form phx-submit="support-fan">
              <div class="flex">
                <input
                  name="supporting"
                  class="w-full rounded border-zinc-300 text-zinc-900"
                  type="number"
                  step="0.01"
                  value={@supporting}
                  phx-debounce="1000"
                />
                <.button
                  class="ml-4 rounded p-4 text-white-100 bg-black"
                >
                  ❣️
                </.button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </.modal>
    <div class="flex gap-8 mx-16">
      <div class="flex-1">
        <div class="w-full mt-4">
          <%= if @playback_url != "" do %>
          <mux-player
            stream-type="live"
            playback-id={@playback_url}
            metadata-video-title="Test video title"
            metadata-viewer-user-id="user-id-007"
          ></mux-player>
          <% end %>
          <div class="mt-4 font-bold">Support (min: 0.01 ETH)</div>
            <form phx-submit="support-creator">
              <div class="flex">
                <input
                  name="supporting"
                  class="w-full rounded border-zinc-300 text-zinc-900"
                  type="number"
                  step="0.01"
                  value={@supporting}
                  phx-debounce="1000"
                />
                <.button
                  class="ml-4 rounded p-4 text-white-100 bg-black"
                >
                  💓
                </.button>
              </div>
            </form>
          </div>
          <.button class="w-full mt-4" phx-click="mint-nft">
            Minting a NFT to be a fan
          </.button>
        </div>
      <div class="flex-1 p-4">
        <div>
          <span id="metamask" phx-hook="Metamask">
            <%= if @connected do %>
              <div>
                <span>chainId</span>: <span><%= @chainId %></span>
              </div>
              <div>
                <span>account</span>: <span><%= @address %></span>
              </div>
              <div>
                <span>balance</span>: <span><%= @balance %> ETH</span>
              </div>
            <% else %>
              <.button phx-click="connect-wallet">
                <span>Connect</span>
              </.button>
            <% end %>
          </span>
        </div>
        <hr class="my-4" />
        <div>
          <div>
            <div class="font-bold">Participants</div>
            <ul>
              <li :for={{address, _meta} <- @presences}>
                <span>- <%= address %></span>
              </li>
            </ul>
          </div>
        </div>
        <hr class="my-4" />
        <div class="font-bold">Messages</div>
        <div
          id="messages_container"
          phx-hook="ScrollToBottom"
          class="max-h-96 overflow-y-auto bg-slate-50 p-2 mt-4"
        >
          <%= for message <- @messages do %>
            <b
              id={to_string(message.id)}
              class="hover:cursor-pointer hover:underline"
              phx-click={show_modal("account-modal")}
            >
              <%= shorten_hex(message.address) %>
            </b>
            <span class="text-sm">
              <%= message.text %> <br />
            </span>
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
            </div>
            <div class="bg-red mt-2 ml-2">
              <.button>
              💬
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

  def handle_event("mint-nft", _params, socket) do
    {:noreply, push_event(socket, "mint-nft", %{})}
  end

  def handle_event("support-creator", %{"supporting" => supporting}, socket) do
    if supporting do
      {:noreply, push_event(socket, "support", %{"supporting" => supporting})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("support-fan", %{"supporting" => supporting}, socket) do
    if supporting do
      {:noreply, push_event(socket, "support-fan", %{"supporting" => supporting, "receiver" => "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("connect-wallet", _params, socket) do
    {:noreply, push_event(socket, "connect-wallet", %{})}
  end

  def handle_event("wallet-connected", params, socket) do
    address = params["address"]

    {:ok, _} =
      Presence.track(self(), @topic, address, %{
        address: address
      })

    presences = Presence.list(@topic)
    socket = assign(socket, :presences, presences)

    message = Map.new()
      |> Map.put("text", "🤚 Welcome, " <> address)
    Messages.create_message(message)

    {:noreply, assign(
      socket,
      connected: true,
      address: address,
      chainId: params["chainId"],
      balance: params["balance"],
      tokenBalance: params["tokenBalance"],
      tokenURI: params["tokenURI"]
    )}
  end

  def handle_event("token-received", params, socket) do
    message = Map.new()
      |> Map.put("text", params["message"])

    Messages.create_message(message)

    {:noreply, assign(socket, tokenBalance: params["tokenBalance"], tokenURI: params["tokenURI"])}
  end

  def handle_event("eth-sent", params, socket) do
    balance = params["balance"]
    message = Map.new()
      |> Map.put("text", params["message"])

    Messages.create_message(message)

    {:noreply, assign(socket, balance: balance)}
  end

  def handle_event("fan-registered", params, socket) do
    message = Map.new()
      |> Map.put("text", params["message"])

    Messages.create_message(message)

    {:noreply, socket}
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

  def shorten_hex_not_colon(hex) do
    case hex do
      nil -> ""
      "" -> ""
      _ -> String.slice(hex, 0, 5) <> "..." <> String.slice(hex, -6, 4)
    end
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
end
