defmodule Wobserver2.System.MemoryTest do
  use ExUnit.Case

  test "usage return memory struct" do
    assert %Wobserver2.System.Memory{} = Wobserver2.System.Memory.usage()
  end

  test "usage returns values" do
    %Wobserver2.System.Memory{
      atom: atom,
      binary: binary,
      code: code,
      ets: ets,
      process: process,
      total: total
    } = Wobserver2.System.Memory.usage()

    assert atom > 0
    assert binary > 0
    assert code > 0
    assert ets > 0
    assert process > 0
    assert total > 0
  end
end
