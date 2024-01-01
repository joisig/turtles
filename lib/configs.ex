defmodule Configs do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  @primary_key {:key, :string, []} # Define :key as the primary key with type :string
  schema "configs" do
    field :value, :map
    timestamps()
  end

  @doc false
  def changeset(config, attrs) do
    config
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
  end

  def all() do
    Turtles.Repo.all(Configs)
    |> Enum.map(&({&1.key, &1.value}))
  end

  def get(key) do
    case Turtles.Repo.get_by(Configs, key: key) do
      nil -> nil
      val -> val.value
    end
  end

  def set(key, value) when is_binary(key) and is_map(value) do
    changeset(%Configs{}, %{key: key, value: value})
    |> Turtles.Repo.insert(on_conflict: {:replace_all_except, [:key]}, conflict_target: [:key])
  end

  def delete(key) when is_binary(key) do
    from(s in Configs, where: s.key == ^key)
    |> Turtles.Repo.delete_all()
  end
end
