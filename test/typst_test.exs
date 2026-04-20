defmodule TypstTest do
  use ExUnit.Case, async: true

  doctest Typst

  test "simple test" do
    assert "= Hello world" == Typst.render_to_string("= Hello <%= name %>", name: "world")

    {:ok, pdf} = Typst.render_to_pdf("= Hello <%= name %>", name: "world")
    assert <<37, 80, 68, 70, 45, _rest::binary>> = pdf

    {:ok, [png]} = Typst.render_to_png("= Hello <%= name %>", name: "world")
    assert <<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>> = png

    {:ok, [svg]} = Typst.render_to_svg("= Hello <%= name %>", name: "world")
    assert svg =~ "<svg"
  end

  describe "virtual files" do
    for image <- ["image.jpg", "image.png", "logo.svg"] do
      test "#{image}" do
        file = Path.join(["test", "assets", unquote(image)]) |> File.read!()

        assert {:ok, _pdf} =
                 Typst.render_to_pdf(~S|#image(read("image", encoding: none))|, [],
                   assets: [image: file]
                 )
      end
    end
  end

  describe "font caching" do
    test "cache_fonts: false still produces valid output" do
      {:ok, pdf} = Typst.render_to_pdf("= cached", [], cache_fonts: false)
      assert <<37, 80, 68, 70, 45, _rest::binary>> = pdf

      {:ok, [png]} = Typst.render_to_png("= cached", [], cache_fonts: false)
      assert <<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>> = png

      {:ok, [svg]} = Typst.render_to_svg("= cached", [], cache_fonts: false)
      assert svg =~ "<svg"
    end

    test "cached calls are faster than uncached" do
      markup = "= benchmark"

      Typst.render_to_pdf(markup)

      {cached_us, {:ok, _}} = :timer.tc(fn -> Typst.render_to_pdf(markup) end)

      {uncached_us, {:ok, _}} =
        :timer.tc(fn -> Typst.render_to_pdf(markup, [], cache_fonts: false) end)

      assert cached_us < uncached_us
    end
  end

  describe "pdf_standards" do
    test "produces a valid PDF when a standard is specified" do
      markup = ~S"""
      #set document(date: datetime(year: 2026, month: 1, day: 1))
      = hello
      """

      {:ok, pdf} = Typst.render_to_pdf(markup, [], pdf_standards: ["a-2b"])
      assert <<37, 80, 68, 70, 45, _rest::binary>> = pdf
    end

    test "returns an error on unknown standard" do
      assert {:error, "unknown PDF standard: a-9z"} =
               Typst.render_to_pdf("= hello", [], pdf_standards: ["a-9z"])
    end
  end

  describe "errors" do
    test "error message on invalid template" do
      template = ~S"#image("

      expected_error =
        """
        [line 1:7] unclosed delimiter
          Source: #image(
                        ^
        """
        |> String.trim_trailing()

      assert {:error, ^expected_error} = Typst.render_to_pdf(template)
    end
  end
end
