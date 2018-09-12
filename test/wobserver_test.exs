defmodule WobserverTest do
  use ExUnit.Case

  alias Wobserver2.Page
  alias Wobserver2.Util.Metrics

  describe "about" do
    test "includes name" do
      assert %{name: "Wobserver"} = Wobserver2.about()
    end

    test "includes version" do
      version =
        case :application.get_key(:wobserver, :vsn) do
          {:ok, v} -> List.to_string(v)
          _ -> "Unknown"
        end

      assert %{version: ^version} = Wobserver2.about()
    end

    test "includes description" do
      assert %{description: "Web based metrics, monitoring, and observer."} = Wobserver2.about()
    end

    test "includes license" do
      %{license: license} = Wobserver2.about()
      assert license.name == "MIT"
    end

    test "includes links" do
      %{links: links} = Wobserver2.about()

      assert Enum.count(links) > 0
    end
  end

  describe "register" do
    test "can register page" do
      assert Wobserver2.register(:page, {"Test", :test, fn -> 5 end})
    end

    test "can register page and also call it" do
      Wobserver2.register(:page, {"Test", :test, fn -> 5 end})

      assert Page.call(:test) == 5
    end

    test "registers a metric" do
      assert Wobserver2.register(:metric, example: {fn -> [{5, []}] end, :gauge, "Description"})

      assert Keyword.has_key?(Metrics.overview(), :example)
    end

    test "registers a metric generator" do
      assert Wobserver2.register(:metric, [
               fn -> [generated: {fn -> [{5, []}] end, :gauge, "Description"}] end
             ])

      assert Keyword.has_key?(Metrics.overview(), :generated)
    end
  end
end
