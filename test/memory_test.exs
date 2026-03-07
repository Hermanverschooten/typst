defmodule Typst.MemoryTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Memory leak tests. Excluded by default.

  Run with: mix test --include memory
  """

  defp rss_mb do
    {output, 0} = System.cmd("ps", ["-o", "rss=", "-p", "#{System.pid()}"])
    ((output |> String.trim() |> String.to_integer()) / 1024) |> Float.round(1)
  end

  defp run_iterations(iterations, fun) do
    :erlang.garbage_collect()

    samples =
      for i <- 1..iterations do
        fun.()

        if rem(i, 100) == 0 do
          :erlang.garbage_collect()
          rss_mb()
        end
      end
      |> Enum.reject(&is_nil/1)

    :erlang.garbage_collect()

    first_sample = List.first(samples)
    last_sample = List.last(samples)
    growth = Float.round(last_sample - first_sample, 1)

    {samples, growth}
  end

  @tag :memory
  @tag timeout: :infinity
  test "PDF render with cached fonts does not leak memory" do
    {_samples, growth} =
      run_iterations(1000, fn ->
        Typst.render_to_pdf!("= Hello World\nThis is a test.", [], cache_fonts: true)
      end)

    assert growth < 50, "Memory grew by #{growth} MB over 1000 iterations"
  end

  @tag :memory
  @tag timeout: :infinity
  test "PDF render with EEx bindings does not leak memory" do
    {_samples, growth} =
      run_iterations(1000, fn ->
        Typst.render_to_pdf!(
          """
          = Report for <%= name %>
          Date: <%= date %>

          #table(
            columns: 3,
            [Item], [Qty], [Price],
            [Widget], [10], [\\$5.00],
            [Gadget], [3], [\\$12.50],
          )
          """,
          [name: "Acme Corp", date: "2026-03-07"],
          cache_fonts: true
        )
      end)

    assert growth < 50, "Memory grew by #{growth} MB over 1000 iterations"
  end

  @tag :memory
  @tag timeout: :infinity
  test "PNG render with cached fonts does not leak memory" do
    {_samples, growth} =
      run_iterations(1000, fn ->
        Typst.render_to_png!("= Hello World\nThis is a test.", [], cache_fonts: true)
      end)

    assert growth < 50, "Memory grew by #{growth} MB over 1000 iterations"
  end
end
