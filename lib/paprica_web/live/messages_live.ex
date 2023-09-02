defmodule PapricaWeb.MessagesLive do
  use PapricaWeb, :live_view

  alias Paprica.Messages
  alias Paprica.Messages.Message

  alias PapricaWeb.Presence

  @topic "account:presences"

  def mount(%{"address" => address}, _session, socket) do
    # Full HTML Page -> Spawn LiveView Process -> make Stateful Connection (connected?)
    if connected?(socket) do
      Messages.subscribe()
      Phoenix.PubSub.subscribe(Paprica.PubSub, @topic)
    end

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

    # IO.inspect(socket, label: "socket")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
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

      <div>
        <div>Who's here?</div>
        <ul>
          <li :for={{address, _meta} <- @presences}>
            <span><%= address %></span>
          </li>
        </ul>
      </div>

      <div
        id="messages_container"
        phx-hook="ScrollToBottom"
        class="p-6 bg-white border rounded shadow max-h-96 overflow-y-auto"
      >
        <%= for message <- @messages do %>
          <b class="text-blue-500"><%= message.address %></b> <%= message.text %> <br />
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
              placeholder="Come on!"
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
    """
  end

  # By convention, all the form params are available under the key message.
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
end
