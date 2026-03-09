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

  describe "to_* functions (no EEx processing)" do
    test "to_pdf compiles plain string" do
      {:ok, pdf} = Typst.to_pdf("= Hello World")
      assert <<37, 80, 68, 70, 45, _rest::binary>> = pdf
    end

    test "to_png compiles plain string" do
      {:ok, [png]} = Typst.to_png("= Hello World")
      assert <<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>> = png
    end

    test "to_svg compiles plain string" do
      {:ok, [svg]} = Typst.to_svg("= Hello World")
      assert svg =~ "<svg"
    end

    test "to_pdf! raises on invalid markup" do
      assert_raise RuntimeError, ~r/could not build pdf/, fn ->
        Typst.to_pdf!(~S|#image(|)
      end
    end

    test "to_png! raises on invalid markup" do
      assert_raise RuntimeError, ~r/could not build png/, fn ->
        Typst.to_png!(~S|#image(|)
      end
    end

    test "to_svg! raises on invalid markup" do
      assert_raise RuntimeError, ~r/could not build svg/, fn ->
        Typst.to_svg!(~S|#image(|)
      end
    end

    test "does not process EEx directives" do
      {:ok, pdf} = Typst.to_pdf("= Hello <%= name %>")
      assert <<37, 80, 68, 70, 45, _rest::binary>> = pdf
    end

    test "supports assets option" do
      file = Path.join(["test", "assets", "image.jpg"]) |> File.read!()

      assert {:ok, _pdf} =
               Typst.to_pdf(~S|#image(read("image", encoding: none))|, assets: [image: file])
    end
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
