defmodule Wobserver2.SystemTest do
  use ExUnit.Case

  describe "overview" do
    test "returns system struct" do
      assert %Wobserver2.System{} = Wobserver2.System.overview()
    end

    test "returns values" do
      %Wobserver2.System{
        architecture: architecture,
        cpu: cpu,
        memory: memory,
        statistics: statistics
      } = Wobserver2.System.overview()

      assert architecture
      assert cpu
      assert memory
      assert statistics
    end
  end
end
