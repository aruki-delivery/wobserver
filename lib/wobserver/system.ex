defmodule Wobserver2.System do
  @moduledoc ~S"""
  Provides System information.
  """

  alias Wobserver2.System.Info
  alias Wobserver2.System.Memory
  alias Wobserver2.System.Scheduler
  alias Wobserver2.System.Statistics

  @typedoc ~S"""
  System overview information.

  Including:
    - `architecture`, architecture information.
    - `cpu`, cpu information.
    - `memory`, memory usage.
    - `statistics`, general System statistics.
    - `scheduler`, scheduler utilization per scheduler.
  """
  @type t :: %__MODULE__{
          architecture: Info.t(),
          cpu: map,
          memory: Memory.t(),
          statistics: Statistics.t(),
          scheduler: list(float)
        }

  defstruct [
    :architecture,
    :cpu,
    :memory,
    :statistics,
    :scheduler
  ]

  @doc ~S"""
  Provides a overview of all System information.

  Including:
    - `architecture`, architecture information.
    - `cpu`, cpu information.
    - `memory`, memory usage.
    - `statistics`, general System statistics.
    - `scheduler`, scheduler utilization per scheduler.
  """
  @spec overview :: Wobserver2.System.t()
  def overview do
    %__MODULE__{
      architecture: Info.architecture(),
      cpu: Info.cpu(),
      memory: Memory.usage(),
      statistics: Statistics.overview(),
      scheduler: Scheduler.utilization()
    }
  end
end
