defmodule PapricaWeb.WebhookController do
  use PapricaWeb, :controller

  alias Paprica.Channels

  def mux(conn, params) do
    IO.inspect(conn, label: "mux_raw_body")
    signature_header = List.first(get_req_header(conn, "mux-signature"))
    raw_body = List.first(conn.assigns.raw_body)

    mux_resource = params["data"]
    mux_live_stream_id = mux_resource["id"]
    channel = Channels.find_by_mux_live_stream_id(mux_live_stream_id)
    IO.inspect(channel, label: "mux mux")

    if channel do
      case Channels.update_from_mux_webhook(channel, params) do
        {:ok, _channel} ->
          json(conn, %{message: "channel updated"})

        {:error, %Ecto.Changeset{} = changeset} ->
          IO.inspect(changeset)

          conn
          |> put_status(500)
          |> json(%{message: "error updating channel", error: changeset})
      end
    else
      json(conn, %{message: "No channel found with that live stream id"})
    end

    # case Mux.Webhooks.verify_header(
    #   raw_body,
    #   signature_header,
    #   "cusafunsilh90oo5jrrtvl8m00gihuj5"
    # ) do
    #   :ok ->
    #     mux_resource = params["data"]
    #     mux_live_stream_id = mux_resource["id"]
    #     channel = Channels.find_by_mux_live_stream_id(mux_live_stream_id)

    #     if channel do
    #       case Channels.update_from_mux_webhook(channel, params) do
    #         {:ok, _channel} ->
    #           json(conn, %{message: "channel updated"})

    #         {:error, %Ecto.Changeset{} = changeset} ->
    #           IO.inspect(changeset)

    #           conn
    #           |> put_status(500)
    #           |> json(%{message: "error updating channel", error: changeset})
    #       end
    #     else
    #       json(conn, %{message: "No channel found with that live stream id"})
    #     end

    #   {:error, message} ->
    #     conn
    #     |> put_status(400)
    #     |> json(%{message: "Error #{message}"})
    # end
  end
end
