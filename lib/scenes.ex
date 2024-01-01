# Copyright (c) 2024 Jói Sigurdsson. All rights reserved.
# Licensed under AGPL, see LICENSE
defmodule Scenes do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  schema "scenes" do
    field :scene, :map
    timestamps()
  end

  @doc false
  def changeset(scene, attrs) do
    scene
    |> cast(attrs, [:scene])
    |> validate_required([:scene])
  end

  def get(id) do
    Turtles.Repo.get_by(Scenes, id: id).scene
  end

  def all() do
    Turtles.Repo.all(Scenes)
    |> Enum.map(&({&1.id, &1.scene}))
    |> Enum.sort(fn {_, lscene}, {_, rscene} ->
      (lscene["position"] || 0.0) <= (rscene["position"] || 0)
    end)
  end

  def add(%{"name" => name, "lights" => lights} = scene_obj) when is_binary(name) and is_list(lights) do
    changeset(%Scenes{}, %{scene: scene_obj})
    |> Turtles.Repo.insert
  end

  def delete(id) when is_integer(id) do
    from(s in Scenes, where: s.id == ^id)
    |> Turtles.Repo.delete_all()
  end

  def apply_scene(%{"name" => _name, "lights" => lights}) do
    for light <- lights do
      Dimmers.set_state(light["dimmerid"], light["is_on"], light["brightness"])
    end
  end
end
