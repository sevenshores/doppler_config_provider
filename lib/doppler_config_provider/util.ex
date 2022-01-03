defmodule DopplerConfigProvider.Util do
  @moduledoc false

  @doc """
  Wrapping this function for the sole purpose of mocking it to test with
  and without the optional dependencies.
  """
  @spec ensure_loaded?(module()) :: boolean()
  def ensure_loaded?(module) do
    Code.ensure_loaded?(module)
  end
end
