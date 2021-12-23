defmodule Ili9486Elixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :ili9486_elixir,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:cvt_color, "~> 0.1.0-dev", github: "cocoa-xu/cvt_color"},
      {:circuits_gpio, "~> 0.4"},
      {:circuits_spi, "~> 0.1"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end
end
