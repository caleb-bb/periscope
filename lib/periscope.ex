defmodule Periscope do
  @moduledoc """
  Tools for dealing with liveview processes, components, sockets, assigns. Pulls this information directly from the list of BEAM processes.
  """

  @doc ~S"""
  liveview_pids returns the PID of every process running a liveview.
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
    Returns a single socket. By default it's the 0th socket in the map, so if your application has only one liveview running, you just want to call this without arguments. If you have multiple liveview processes, then you'll want to use all_sockets to view the list and grab the one you want using this function.
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
    Returns a list of active comoponent names. These are module names, so you only see one per module. Even if one component is rendered many times, you will only see its name once. If you want to see how many instances of a component are rendered. use components/0.
  """
  def component_names do
    Enum.flat_map(
      component_states(),
      &(&1.components |> elem(1))
    )
    |> Enum.map(&elem(&1, 0))
  end

  #TODO: make this return a map instead! This sets us up to get paths by liveviews.
  def paths_and_liveviews(your_app_web) do
    your_app_web.__routes__()
    |> Enum.filter(&(&1.metadata |> Map.has_key?(:phoenix_live_view)))
    |> Enum.map(&{&1.path, &1.metadata.phoenix_live_view |> elem(0)})
  end

  def web_module do
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

  def paths_and_liveviews do
    module = web_module() <> "Web"

    Module.concat([module, "Router"])
    |> paths_and_liveviews()

    # then(&(&1.__routes__()))
  end

  def components_to_assigns do
    components = (component_states() |> hd).components
    components
    |> elem(0)
    |> Map.values()
    |> Enum.map(&{elem(&1,0), elem(&1,2)})
    |> Enum.into(%{})
  end

  def assigns_for(component) do
    Map.get(components_to_assigns(), component)
  end

end
