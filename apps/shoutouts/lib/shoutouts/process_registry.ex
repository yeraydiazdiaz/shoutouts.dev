defmodule Shoutouts.ProcessRegistry do
  @moduledoc """
  Generic process registry.
  """

  def start_link do
    # we create a Registry process with this module's name
    # ensuring only one process can be mapped to a key
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(key) do
    # convenience function for other modules to use to register their processes
    {:via, Registry, {__MODULE__, key}}
  end

  def child_spec(_) do
    # override child spec forwarding it to the Registry but injecting
    # the modules name in the id and the start keys
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
