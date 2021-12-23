# ILI9486-Elixir

ILI9486 driver for Elixir.

Tested on Waveshare 3.5" SPI LCD RPi LCD (A) (480x320).

## Example

```elixir
# default (Waveshare 3.5" SPI LCD RPi LCD (A) (480x320))
# assuming LCD device at /dev/spidev0.0
# DC connects to PIN 24
# RST not connected
# SPI speed: 16MHz
# Pixel Format: BGR565
disp = ILI9486.new()
```

```elixir
# high-speed variant (125MHz SPI) (Waveshare 3.5" SPI LCD RPi LCD (C) (480x320))
# assuming LCD device at /dev/spidev0.0
# DC connects to PIN 24
# RST connects to PIN 25 (for demo only, not necessary)
# SPI speed: 125MHz
# Pixel Format: BGR666 (for demo only, not necessary)
disp = ILI9486.new(is_high_speed: true, speed_hz: 125_000_000, pix_fmt: :bgr666, rst: 25)
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ili9486_elixir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ili9486_elixir, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ili9486_elixir](https://hexdocs.pm/ili9486_elixir).

