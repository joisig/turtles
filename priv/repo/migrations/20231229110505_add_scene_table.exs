defmodule Turtles.Repo.Migrations.AddSceneTable do
  use Ecto.Migration

  def change do
    create table(:scenes) do
      add :scene, :map
      timestamps()
    end
    create table(:configs, primary_key: false) do
      add :key, :string, primary_key: true
      add :value, :map
      timestamps()
    end
  end
end
