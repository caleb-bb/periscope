defmodule Periscope do
  @moduledoc """
  Tools for dealing with liveview processes, components, sockets, assigns. Pulls this information directly from the list of BEAM processes.
  """

  @doc ~S"""
  liveview_pids returns the PID of every process if that process contains a liveview.
  """
  @spec liveview_pids :: [pid] | []
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
        elem(proc, 1) == :mount
    end)
    |> Enum.map(&elem(&1, 0))
  end

  @doc ~S"""
  Used for testing handle_info/2 callback.
  """
  def message(msg, socket_number // 0), do: send(socket(socket_number).assigns.root_pid, msg)

  @doc ~S"""
  Returns the sockets for all active liveviews in a 0-indexed map. So all_sockets(0) will return the first socket in the map.
  """
  @spec all_sockets :: map
  def all_sockets do
    component_states()
    |> Enum.map(& &1.socket)
    |> Enum.with_index(fn socket, index -> {index, socket} end)
    |> Enum.into(%{})
  end

  @doc ~S"""
  Returns a list of liveview module names. Expect to see stuff like MyApp.CustomerWorkflow or some such name. This does NOT list the names of components. Use components/0 for that.
  """
  @spec all_liveviews :: [module] | []
  def all_liveviews do
    Enum.map(component_states(), & &1.socket)
    |> Enum.with_index(fn socket, index -> {index, socket.view} end)
    |> Enum.into(%{})
  end

  @doc ~S"""
    Returns a single socket. You can access the assigns using socket.assigns. However, socket.assigns will not show the assigns on the components (see component_names).
  """
  @spec socket(non_neg_integer) :: map
  def socket(socket_index \\ 0) do
    Map.get(all_sockets(), socket_index)
  end

  @doc ~S"""
    as socket/1, but for liveview names.
  """
  @spec which_liveview(non_neg_integer) :: map
  def which_liveview(socket_index \\ 0) do
    socket(socket_index).view
  end

  @doc ~S"""
    Returns a list of active component names. These are module names, so you only see one per module. Even if one component is rendered many times, you will only see its name once. If you want to see how many instances of a component are rendered. use components/0.

  Note that components have their own assigns. If you want to see the assigns for a component, you can use assigns_for/1.
  """
  @spec component_names :: list
  def component_names do
    Enum.flat_map(
      component_states(),
      &(&1.components |> elem(1))
    )
    |> Enum.map(&elem(&1, 0))
  end

  @doc ~S"""
  Returns a map whose keys are component names (as those found in component_names) and whose values are the assigns for those components.
  """
  @spec components_to_assigns :: map
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
  @spec assigns_for(binary) :: map
  def assigns_for(component) do
    Map.get(components_to_assigns(), component)
  end

  # Helper function for extracting state from a list of pids.
  defp component_states do
    Enum.map(liveview_pids(), &:sys.get_state/1)
  end
end
