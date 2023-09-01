defmodule Paprica.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :text, :string
      add :address, :string
      add :country, :string

      timestamps()
    end
  end
end
