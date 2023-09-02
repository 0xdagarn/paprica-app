defmodule Paprica.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :address, :string, default: ""
    field :country, :string, default: ""
    field :text, :string

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:text, :address, :country])
    |> validate_required([:text])
  end
end
