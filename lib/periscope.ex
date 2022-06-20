defmodule Periscope do
  @moduledoc """
  Tools for dealing with liveview processes, components, sockets, assigns. Pulls this information directly from the list of BEAM processes.
  """

  @doc ~S"""
  liveview_pids returns the PID of every process iff that process contains a liveview.
  """
  def liveview_pids do
    Process.list()
    |> Enum.map(
      &{
        &1,
        Process.info(&1, [:dictionary])
        |> hd()
        |> elem(1)
        |> Keyword.get(:"$initial_call", {})
      }
    )
    |> Enum.filter(fn {_, proc} ->
      proc != nil && proc != {} &&
        elem(proc, 0) == Phoenix.LiveView.Channel
    end)
    |> Enum.map(&elem(&1, 0))
  end

  # Helper function for extracting state from a list of pids.
  defp component_states do
    Enum.map(liveview_pids(), &:sys.get_state/1)
  end

  @doc ~S"""
  Returns the sockets for all active liveviews in a 0-indexed map. So all_sockets(0) will return the first socket in the map.
  """
  def all_sockets do
    component_states()
    |> Enum.map(& &1.socket)
    |> Enum.with_index(fn socket, index -> {index, socket} end)
    |> Enum.into(%{})
  end

  @doc ~S"""
  Returns a list of liveview module names. Expect to see stuff like MyApp.CustomerWorkflow or some such name. This does NOT list the names of components. Use components/0 for that.
  """
  def all_liveviews do
    Enum.map(component_states(), & &1.socket)
    |> Enum.with_index(fn socket, index -> {index, socket.view} end)
    |> Enum.into(%{})
  end

  @doc ~S"""
    Returns a single socket. You can access the assigns using socket.assigns. However, socket.assigns will not show the assigns on the components (see component_names).
  """
  def socket(socket_index \\ 0) do
    Map.get(all_sockets(), socket_index)
  end

  @doc ~S"""
    as socket/1, but for liveview names.
  """
  def which_liveview(socket_index \\ 0) do
    socket(socket_index).view
  end

  @doc ~S"""
    Returns a list of active component names. These are module names, so you only see one per module. Even if one component is rendered many times, you will only see its name once. If you want to see how many instances of a component are rendered. use components/0.

  Note that components have their own assigns. If you want to see the assigns for a component, you can use assigns_for/1.
  """
  @spec component_names() :: list
  def component_names do
    Enum.flat_map(
      component_states(),
      &(&1.components |> elem(1))
    )
    |> Enum.map(&elem(&1, 0))
  end

  @doc ~S"""
  Takes the last part of a schema module name and returns all the fields in that schema. So running `schema_fields(Comments)` in an app called MyBlog will return all fields for MyBlog.Schemas.Comments. Note that this isn't a string, so you pass in Comments, not "Comments".
  """
  def schema_fields(schema_module) do
    schema_name = Module.concat(application_name(), "Schemas." <> schema_module)

    schema_name.__schema__(:fields)
  end

  @doc ~S"""
  Returns the name of your top-level application. This is used by other search functions when they need to find/list modules.
  """
  def application_name do
    {:ok, lib_dir} =
      (Path.expand("") <> "/lib")
      |> File.ls()

    lib_dir
    |> Enum.filter(&String.ends_with?(&1, "web"))
    |> hd()
    |> String.split("_")
    |> hd()
    |> String.capitalize()
  end

  @doc ~S"""
  Will return a list of tuples where the first element of each tuple is the router path that accesses a given liveview and the second element is the name of that liveview. Useful if you want to access a component fast without having to scroll through the router and figure out its URL.
  """
  def liveviews_to_paths do
    app = application_name() <> "Web"

    Module.concat([app, "Router"])
    |> liveviews_to_paths()
  end

  defp liveviews_to_paths(your_app_web) do
    your_app_web.__routes__()
    |> Enum.filter(&is_a_liveview_route?/1)
    |> Enum.map(&liveview_route_to_path/1)
    |> Enum.reduce(%{}, &aggregate_merge(&1, &2))
  end
  
  defp liveview_route_to_path(route) do
    {liveview, path} = {
      route.metadata.phoenix_live_view |> elem(0),
      route.path
    }

    %{liveview => [path]}
  end

  @doc ~S"""
  Returns a map whose keys are component names (as those found in component_names) and whose values are the assigns for those components.
  """
  def components_to_assigns do
    components = (component_states() |> hd).components

    components
    |> elem(0)
    |> Map.values()
    |> Enum.map(&{elem(&1, 0), elem(&1, 2)})
    |> Enum.into(%{})
  end

  @doc ~S"""
  Returns the assigns for the fully-qualified component name, e.g. assigns_for(MyappWeb.MainView.Table) will return the assigns for that component.
  """
  def assigns_for(component) do
    Map.get(components_to_assigns(), component)
  end

  @doc ~S"""
  Takes a route and returns true if it's a route to a liveview module.
  """
  def is_a_liveview_route?(route) do
    Map.has_key?(route.metadata, :phoenix_live_view)
  end

  @doc ~S"""
  Merges maps. If a key has different values in each map, they are aggregated into a list.

  ## Examples
    iex> Periscope.aggregate_merge(%{a: 1, b: [2, 3], c: [4]}, %{a: [5, 6], b: 7, c: [8, 9, 10, 11]})
    %{a: [1, 5, 6], b: [2, 3, 7], c: [4, 8, 9, 10, 11]}
  """

  def aggregate_merge(a, b) do
    Map.merge(a, b, fn _k, v1, v2 -> List.flatten([v1, v2]) end)
  end
end
