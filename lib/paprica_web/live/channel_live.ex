defmodule PapricaWeb.ChannelLive do
  use PapricaWeb, :live_view

  alias Paprica.Channels
  alias Paprica.Channels.Channel

  def mount(_params, _session, socket) do
    changeset = Channels.change_channel(%Channel{})
    form = to_form(changeset)

    socket =
      socket
      |> assign(:form, form)
      |> assign(:stream_key, "")
      |> assign(:channel, %Channel{})

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Create your Channel</h1>
      <.form
        id="channel_form"
        for={@form}
        phx-submit="create"
      >
        <div class="flex">
          <div class="w-full">
            <.input
              field={@form[:slug]}
              placeholder="channel slug"
              autocomplete="off"
            />
            <%!-- <.input field={@form[:country]} placeholder="Come on!" autocomplete="off" />
            <.input field={@form[:address]} placeholder="Come on!" autocomplete="off" /> --%>
          </div>
          <div class="bg-red mt-2 ml-2">
            <.button>
              Create
            </.button>
          </div>
        </div>
      </.form>
      <div class="mt-4">
        Your stream key: <%= @stream_key %>
      </div>
      <%= if @stream_key != "" do %>
        <div class="mt-2 text-blue-700">
          <.link href={~p"/channel/" <> @channel.slug}><%= "👉 /channel/" <> @channel.slug %></.link>
        </div>
      <%= end %>
    </div>
    """
  end

  def handle_event("create", %{"channel" => channel_param}, socket) do
    # %{"channel" => channel_param}

    case Channels.create_channel(channel_param) do
      {:ok, channel} ->
        {:ok, live_stream, _env} = Mux.Video.LiveStreams.create(Mux.client(), %{
          playback_policy: "public",
          new_asset_settings: %{playback_policy: "public"}
        })

        stream_key = live_stream["stream_key"]
        live_stream_id = live_stream["id"]

        {:ok, channel} = Channels.update_channel(channel, %{
          stream_key: stream_key,
          mux_resource: live_stream,
          mux_live_stream_id: live_stream_id
        })

        changeset = Channels.change_channel(%Channel{})

        {:noreply, assign(socket, stream_key: stream_key, form: to_form(changeset), channel: channel)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end

    # message = message_param
    #   |> Map.put("address", socket.assigns.address)
    #   |> Map.put("country", "KOR")
    # IO.inspect(message, label: "message")

    # case Messages.create_message(message) do
    #   {:ok, _message} ->
    #     changeset = Messages.change_message(%Message{})
    #     IO.inspect(changeset, label: "changeset")

    #     {:noreply, assign(socket, form: to_form(changeset))}

    #   {:error, changeset} ->
    #     {:noreply, assign(socket, form: to_form(changeset))}
    # end
  end

  def handle_event("go", _params, socket) do
    {:ok, redirect(socket, to: "/channel" <> socket.assigns.slug)}
  end
end
