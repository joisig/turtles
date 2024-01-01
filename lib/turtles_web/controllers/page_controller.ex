defmodule TurtlesWeb.PageController do
  use TurtlesWeb, :controller

  def home(conn, _params) do
    dimmers = Dimmers.all_states()
    |> Enum.map(fn {id, name, {is_on, brightness}} ->
      %{id: id, name: name, is_on: is_on, brightness: brightness}
    end)

    scenes = Scenes.all

    render(conn,
      :home,
      layout: false,
      dimmers: dimmers,
      scenes: scenes)
  end

  def set_scene(conn, %{"scene" => scene_id}) do
    scene = Scenes.get(scene_id)
    Scenes.apply_scene(scene)

    conn
    |> put_flash(:info, "Scene applied")
    |> redirect(to: "/")
  end

  def set_light_state(conn, %{"dimmer_name" => dimmer_name, "is_on" => is_on, "brightness" => brightness}) do
    Dimmers.set_state(dimmer_name, is_on, brightness)
    conn |> send_resp(200, "ok")
  end

  def manage_scenes(conn, _) do
    render(conn, :manage, layout: false, scenes: Scenes.all)
  end

  def delete_scene(conn, %{"scene" => scene_id}) do
    {id, ""} = Integer.parse(scene_id)
    Scenes.delete(id)

    conn
    |> put_flash(:info, "Scene deleted")
    |> redirect(to: "/")
  end

  def new_scene(conn, params) do
    dimmers = Dimmers.all_states()
    |> Enum.map(fn {id, name, {is_on, brightness}} ->
      %{id: id, name: name, is_on: is_on, brightness: brightness}
    end)

    render(conn, :new, layout: false, dimmers: dimmers)
  end

  def create(conn, %{"scene_name" => name, "include_lights" => include_lights}) do
    lights = Dimmers.all_states()
    |> Enum.flat_map(fn {id, _name, {is_on, brightness}} ->
      if id in include_lights do
        [%{"dimmerid" => id, "is_on" => is_on, "brightness" => brightness}]
      else
        []
      end
    end)

    Scenes.add(%{"name" => name, "lights" => lights})

    conn
    |> put_flash(:info, "Scene created")
    |> redirect(to: "/")
  end
end
