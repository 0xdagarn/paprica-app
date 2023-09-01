defmodule Paprica.MessagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Paprica.Messages` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        address: "some address",
        country: "some country",
        text: "some text"
      })
      |> Paprica.Messages.create_message()

    message
  end
end
