defmodule ILI9486 do
  @moduledoc """
  ILI9486 Elixir driver
  """

  use Bitwise

  @enforce_keys [:gpio, :opts, :lcd_spi, :data_bus, :display_mode]
  defstruct [
    :gpio,
    :opts,
    :lcd_spi,
    :touch_spi,
    :pix_fmt,
    :rotation,
    :mad_mode,
    :data_bus,
    :display_mode
  ]

  @doc """
  New connection to an ILI9486

  - **port**: SPI port number

    Default value: `0`

  - **lcd_cs**: LCD chip-selection number

    Default value: `0`.

  - **touch_cs**: (Optional) Touch panel chip-selection number

    Default value: `nil`.

  - **dc**: Command/data register selection

    Default value: `24`.

  - **rst**: Reset pin for ILI9486

    Default value: `nil`.

  - **width**: Width of display connected to ILI9486

    Default value: `480`.

  - **height**: Height of display connected to ILI9486

    Default value: `320`.

  - **offset_top**: Offset to top row

    Default value: `0`.

  - **offset_left**: Offset to left column

    Default value: `0`.

  - **speed_hz**: SPI speed (in Hz)

    Default value: `16_000_000`.

  - **pix_fmt**: either `:bgr565`, `:rgb565`, `:bgr666` or `:rgb666`

    Default value: `:bgr565`.

  - **rotation**: Screen rotation.

    Default value: `90`. Only `0`, `90`, `180` and `270` are valid.

  - **mad_mode**: MAD mode.

    Default value: `:right_down`. Valid values: `:right_down`, `:right_up` and `:rgb_mode`

  **return**: `%ILI9486{}`

  ## Example
  ```elixir
  # default
  # assuming LCD device at /dev/spidev0.0
  # DC connects to PIN 24
  # RST not connected
  # SPI speed: 16MHz
  # Pixel Format: BGR565
  disp = ILI9486.new()
  ```
  """
  @doc functions: :exported
  def new(opts \\ []) do
    port = opts[:port] || 0
    lcd_cs = opts[:lcd_cs] || 0
    touch_cs = opts[:touch_cs]
    dc = opts[:dc] || 24
    speed_hz = opts[:speed_hz] || 16_000_000
    width = opts[:width] || 480
    height = opts[:height] || 320
    offset_top = opts[:offset_top] || 0
    offset_left = opts[:offset_left] || 0
    rst = opts[:rst]
    pix_fmt = opts[:pix_fmt] || :bgr565
    rotation = opts[:rotation] || 90
    mad_mode = opts[:mad_mode] || :right_down
    data_bus = opts[:data_bus] || :parallel_8bit
    display_mode = opts[:display_mode] || :normal

    # supported data connection
    # only 8-bit parallel MCU interface for now
    # - 65K colors
    # - 262K colors
    :parallel_8bit = data_bus

    {:ok, lcd_spi} = init_spi(port, lcd_cs, speed_hz)
    {:ok, touch_spi} = init_spi(port, touch_cs, speed_hz)

    # Set DC as output.
    {:ok, gpio_dc} = Circuits.GPIO.open(dc, :output)

    # Setup reset as output (if provided).
    gpio_rst = init_reset(rst)

    %ILI9486{
      lcd_spi: lcd_spi,
      touch_spi: touch_spi,
      gpio: [
        dc: gpio_dc,
        rst: gpio_rst
      ],
      opts: [
        port: port,
        lcd_cs: lcd_cs,
        touch_cs: touch_cs,
        dc: dc,
        speed_hz: speed_hz,
        width: width,
        height: height,
        offset_top: offset_top,
        offset_left: offset_left,
        rst: rst
      ],
      pix_fmt: pix_fmt,
      rotation: rotation,
      mad_mode: mad_mode,
      data_bus: data_bus,
      display_mode: display_mode
    }
    |> ILI9486.reset()
    |> init()
  end

  @doc """
  Reset the display, if reset pin is connected.

  - **self**: `%ILI9486{}`

  **return**: `self`
  """
  @doc functions: :exported
  def reset(self = %ILI9486{gpio: gpio}) do
    gpio_rst = gpio[:rst]

    if gpio_rst != nil do
      Circuits.GPIO.write(gpio_rst, 1)
      :timer.sleep(500)
      Circuits.GPIO.write(gpio_rst, 0)
      :timer.sleep(500)
      Circuits.GPIO.write(gpio_rst, 1)
      :timer.sleep(500)
    end

    self
  end

  @doc """
  Get screen size

  - **self**: `%ILI9486{}`

  **return**: `%{height: height, width: width}`
  """
  @doc functions: :exported
  def size(%ILI9486{opts: opts}) do
    %{height: opts[:height], width: opts[:width]}
  end

  @doc """
  Get display pixel format

  - **self**: `%ILI9486{}`

  **return**: either `:bgr565` or `:rgb565`
  """
  @doc functions: :exported
  def pix_fmt(%ILI9486{pix_fmt: pix_fmt}) do
    pix_fmt
  end

  @doc """
  Set display pixel format

  - **self**: `%ILI9486{}`
  - **pix_fmt**: either `:bgr565` or `:rgb565`

  **return**: `self`
  """
  @doc functions: :exported
  def set_pix_fmt(self = %ILI9486{}, pix_fmt = :bgr565) do
    %ILI9486{self | pix_fmt: pix_fmt}
    |> command(kMADCTL(), cmd_data: _mad_mode(self))
  end

  def set_pix_fmt(self = %ILI9486{}, pix_fmt = :rgb565) do
    %ILI9486{self | pix_fmt: pix_fmt}
    |> command(kMADCTL(), cmd_data: _mad_mode(self))
  end

  @doc """
  Turn on/off display

  - **self**: `%ILI9486{}`
  - **status**: either `:on` or `:off`

  **return**: `self`
  """
  @doc functions: :exported
  def set_display(self = %ILI9486{}, :on) do
    command(self, kDISPON())
  end

  def set_display(self = %ILI9486{}, :off) do
    command(self, kDISPOFF())
  end

  @doc """
  Set display mode

  - **self**: `%ILI9486{}`
  - **display_mode**: Valid values: `:normal`, `:partial`, `:idle`

  **return**: `self`
  """
  @doc functions: :exported
  def set_display_mode(self = %ILI9486{}, display_mode = :normal) do
    %ILI9486{self | display_mode: display_mode}
    |> command(kNORON())
  end

  def set_display_mode(self = %ILI9486{}, display_mode = :partial) do
    %ILI9486{self | display_mode: display_mode}
    |> command(kPTLON())
  end

  def set_display_mode(self = %ILI9486{}, display_mode = :idle) do
    %ILI9486{self | display_mode: display_mode}
    |> command(self, kIDLEON())
  end

  @doc """
  Write the provided 16bit BGR565/RGB565 image to the hardware.

  - **self**: `%ILI9486{}`
  - **image_data**: Should be 16bit BGR565/RGB565 format (same channel order as in `self`) and
    the same dimensions (width x height x 3) as the display hardware.

  **return**: `self`
  """
  @doc functions: :exported
  def display_565(self, image_data) when is_binary(image_data) do
    display_565(self, :binary.bin_to_list(image_data))
  end

  def display_565(self, image_data) when is_list(image_data) do
    self
    |> set_window(x0: 0, y0: 0, x1: nil, y2: nil)
    |> send(image_data, true, 4096)
  end

  @doc """
  Write the provided 18bit BGR666/RGB666 image to the hardware.

  - **self**: `%ILI9486{}`
  - **image_data**: Should be 18bit BGR666/RGB666 format (same channel order as in `self`) and
    the same dimensions (width x height x 3) as the display hardware.

  **return**: `self`
  """
  @doc functions: :exported
  def display_666(self, image_data) when is_binary(image_data) do
    display_666(self, :binary.bin_to_list(image_data))
  end

  def display_666(self, image_data) when is_list(image_data) do
    self
    |> set_window(x0: 0, y0: 0, x1: nil, y2: nil)
    |> send(image_data, true, 4096)
  end

  @doc """
  Write the provided 24bit BGR888/RGB888 image to the hardware.

  - **self**: `%ILI9486{}`
  - **image_data**: Should be 24bit format and the same dimensions (width x height x 3) as the display hardware.
  - **pix_fmt**: Either `:rgb888` or `:bgr888`. Indicates the channel order of the provided `image_data`.

  **return**: `self`
  """
  @doc functions: :exported
  def display(self = %ILI9486{pix_fmt: target_color}, image_data, source_color)
      when is_binary(image_data) and (source_color == :rgb888 or source_color == :bgr888) and
             (target_color == :rgb565 or target_color == :bgr565) do
    display_565(self, to_565(image_data, source_color, target_color))
  end

  def display(self = %ILI9486{pix_fmt: target_color}, image_data, source_color)
      when is_binary(image_data) and (source_color == :rgb888 or source_color == :bgr888) and
             (target_color == :rgb666 or target_color == :bgr666) do
    display_666(self, :binary.bin_to_list(image_data))
  end

  def display(self, image_data, source_color)
      when is_list(image_data) and (source_color == :rgb888 or source_color == :bgr888) do
    display(
      self,
      Enum.map(image_data, &Enum.into(&1, <<>>, fn bit -> <<bit::8>> end)),
      source_color
    )
  end

  @doc """
  Write a byte to the display as command data.

  - **self**: `%ILI9486{}`
  - **cmd**: command data
  - **opts**:
    - **cmd_data**: cmd data to be sent.
      Default value: `[]`. (no data will be sent)
    - **delay**: wait `delay` ms after the cmd data is sent
      Default value: `0`. (no wait)

  **return**: `self`
  """
  @doc functions: :exported
  def command(self, cmd, opts \\ []) when is_integer(cmd) do
    cmd_data = opts[:cmd_data] || []
    delay = opts[:delay] || 0

    self
    |> send(cmd, false)
    |> data(cmd_data)

    :timer.sleep(delay)
    self
  end

  @doc """
  Write a byte or array of bytes to the display as display data.

  - **self**: `%ILI9486{}`
  - **data**: display data

  **return**: `self`
  """
  @doc functions: :exported
  def data(self, []), do: self

  def data(self, data) do
    send(self, data, true)
  end

  @doc """
  Send bytes to the ILI9486

  - **self**: `%ILI9486{}`
  - **bytes**: The bytes to be sent to `self`

    - `when is_integer(bytes)`,
      `sent` will take the 8 least-significant bits `[band(bytes, 0xFF)]`
      and send it to `self`
    - `when is_list(bytes)`, `bytes` will be casting to bitstring and then sent
      to `self`

  - **is_data**:

    - `true`: `bytes` will be sent as data
    - `false`: `bytes` will be sent as commands

  - **chunk_size**: Indicates how many bytes will be send in a single write call

  **return**: `self`
  """
  @doc functions: :exported
  def send(self, bytes, is_data, chunk_size \\ 4096)

  def send(self = %ILI9486{}, bytes, true, chunk_size) do
    send(self, bytes, 1, chunk_size)
  end

  def send(self = %ILI9486{}, bytes, false, chunk_size) do
    send(self, bytes, 0, chunk_size)
  end

  def send(self = %ILI9486{}, bytes, is_data, chunk_size)
      when (is_data == 0 or is_data == 1) and is_integer(bytes) do
    send(self, [Bitwise.band(bytes, 0xFF)], is_data, chunk_size)
  end

  def send(self = %ILI9486{gpio: gpio, lcd_spi: spi}, bytes, is_data, chunk_size)
      when (is_data == 0 or is_data == 1) and is_list(bytes) do
    gpio_dc = gpio[:dc]

    if gpio_dc != nil do
      Circuits.GPIO.write(gpio_dc, is_data)

      for xfdata <-
            bytes
            |> Enum.chunk_every(chunk_size)
            |> Enum.map(&Enum.into(&1, <<>>, fn bit -> <<bit::8>> end)) do
        {:ok, _ret} = Circuits.SPI.transfer(spi, xfdata)
      end

      self
    else
      {:error, "gpio[:dc] is nil"}
    end
  end

  defp init_spi(_port, nil, _speed_hz), do: {:ok, nil}

  defp init_spi(port, cs, speed_hz) when cs >= 0 do
    Circuits.SPI.open("spidev#{port}.#{cs}", speed_hz: speed_hz)
  end

  defp init_spi(_port, _cs, _speed_hz), do: nil

  defp init_reset(nil), do: nil

  defp init_reset(rst) when rst >= 0 do
    {:ok, gpio} = Circuits.GPIO.open(rst, :output)
    gpio
  end

  defp init_reset(_), do: nil

  defp _get_channel_order(%ILI9486{pix_fmt: :rgb565}), do: kMAD_RGB()
  defp _get_channel_order(%ILI9486{pix_fmt: :bgr565}), do: kMAD_BGR()
  defp _get_channel_order(%ILI9486{pix_fmt: :rgb666}), do: kMAD_RGB()
  defp _get_channel_order(%ILI9486{pix_fmt: :bgr666}), do: kMAD_BGR()

  defp _get_pix_fmt(%ILI9486{pix_fmt: :rgb565}), do: k16BIT_PIX()
  defp _get_pix_fmt(%ILI9486{pix_fmt: :bgr565}), do: k16BIT_PIX()
  defp _get_pix_fmt(%ILI9486{pix_fmt: :rgb666}), do: k18BIT_PIX()
  defp _get_pix_fmt(%ILI9486{pix_fmt: :bgr666}), do: k18BIT_PIX()

  defp _mad_mode(self = %ILI9486{rotation: 0, mad_mode: :right_down}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_RIGHT())
    |> bor(kMAD_Y_DOWN())
  end

  defp _mad_mode(self = %ILI9486{rotation: 90, mad_mode: :right_down}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_LEFT())
    |> bor(kMAD_Y_DOWN())
    |> bor(kMAD_VERTICAL())
  end

  defp _mad_mode(self = %ILI9486{rotation: 180, mad_mode: :right_down}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_LEFT())
    |> bor(kMAD_Y_UP())
  end

  defp _mad_mode(self = %ILI9486{rotation: 270, mad_mode: :right_down}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_RIGHT())
    |> bor(kMAD_Y_UP())
    |> bor(kMAD_VERTICAL())
  end

  defp _mad_mode(self = %ILI9486{rotation: 0, mad_mode: :right_up}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_RIGHT())
    |> bor(kMAD_Y_UP())
  end

  defp _mad_mode(self = %ILI9486{rotation: 90, mad_mode: :right_up}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_RIGHT())
    |> bor(kMAD_Y_DOWN())
    |> bor(kMAD_VERTICAL())
  end

  defp _mad_mode(self = %ILI9486{rotation: 180, mad_mode: :right_up}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_LEFT())
    |> bor(kMAD_Y_DOWN())
  end

  defp _mad_mode(self = %ILI9486{rotation: 270, mad_mode: :right_up}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_LEFT())
    |> bor(kMAD_Y_UP())
    |> bor(kMAD_VERTICAL())
  end

  defp _mad_mode(self = %ILI9486{rotation: 0, mad_mode: :rgb_mode}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_LEFT())
    |> bor(kMAD_Y_DOWN())
  end

  defp _mad_mode(self = %ILI9486{rotation: 90, mad_mode: :rgb_mode}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_RIGHT())
    |> bor(kMAD_Y_DOWN())
  end

  defp _mad_mode(self = %ILI9486{rotation: 180, mad_mode: :rgb_mode}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_RIGHT())
    |> bor(kMAD_Y_UP())
  end

  defp _mad_mode(self = %ILI9486{rotation: 270, mad_mode: :rgb_mode}) do
    self
    |> _get_channel_order()
    |> bor(kMAD_X_LEFT())
    |> bor(kMAD_Y_UP())
  end

  defp init(self = %ILI9486{}) do
    self
    # software reset
    |> command(kSWRESET(), delay: 120)
    # RGB mode off
    |> command(kRGB_INTERFACE(), cmd_data: 0x00)
    # turn off sleep mode
    |> command(kSLPOUT(), delay: 200)
    # interface format
    |> command(kPIXFMT(), cmd_data: _get_pix_fmt(self))
    |> command(kMADCTL(), cmd_data: _mad_mode(self))
    |> command(kPWCTR3(), cmd_data: 0x44)
    |> command(kVMCTR1(), cmd_data: [0x00, 0x00, 0x00, 0x00])
    |> command(kGMCTRP1(),
      cmd_data: [
        0x0F,
        0x1F,
        0x1C,
        0x0C,
        0x0F,
        0x08,
        0x48,
        0x98,
        0x37,
        0x0A,
        0x13,
        0x04,
        0x11,
        0x0D,
        0x00
      ]
    )
    |> command(kGMCTRN1(),
      cmd_data: [
        0x0F,
        0x32,
        0x2E,
        0x0B,
        0x0D,
        0x05,
        0x47,
        0x75,
        0x37,
        0x06,
        0x10,
        0x03,
        0x24,
        0x20,
        0x00
      ]
    )
    |> command(kDGCTR1(),
      cmd_data: [
        0x0F,
        0x32,
        0x2E,
        0x0B,
        0x0D,
        0x05,
        0x47,
        0x75,
        0x37,
        0x06,
        0x10,
        0x03,
        0x24,
        0x20,
        0x00
      ]
    )
    |> set_display_mode(:normal)
    |> command(kINVOFF())
    |> command(kSLPOUT(), delay: 200)
    |> command(kDISPON())
  end

  defp set_window(self = %ILI9486{opts: board}, opts = [x0: 0, y0: 0, x1: nil, y2: nil]) do
    width = board[:width]
    height = board[:height]
    offset_top = board[:offset_top]
    offset_left = board[:offset_left]
    x0 = opts[:x0]
    x1 = opts[:x1]
    x1 = if x1 == nil, do: width - 1
    y0 = opts[:y0]
    y1 = opts[:y1]
    y1 = if y1 == nil, do: height - 1
    y0 = y0 + offset_top
    y1 = y1 + offset_top
    x0 = x0 + offset_left
    x1 = x1 + offset_left

    self
    |> command(kCASET())
    |> data(bsr(x0, 8))
    |> data(band(x0, 0xFF))
    |> data(bsr(x1, 8))
    |> data(band(x1, 0xFF))
    |> command(kPASET())
    |> data(bsr(y0, 8))
    |> data(band(y0, 0xFF))
    |> data(bsr(y1, 8))
    |> data(band(y1, 0xFF))
    |> command(kRAMWR())
  end

  defp to_565(image_data, source_color, target_color)
       when is_binary(image_data) do
    image_data
    |> CvtColor.cvt(source_color, target_color)
    |> :binary.bin_to_list()
  end

  @doc functions: :constants
  def kNOP, do: 0x00
  @doc functions: :constants
  def kSWRESET, do: 0x01

  @doc functions: :constants
  def kRDDID, do: 0x04
  @doc functions: :constants
  def kRDDST, do: 0x09
  @doc functions: :constants
  def kRDMODE, do: 0x0A
  @doc functions: :constants
  def kRDMADCTL, do: 0x0B
  @doc functions: :constants
  def kRDPIXFMT, do: 0x0C
  @doc functions: :constants
  def kRDIMGFMT, do: 0x0D
  @doc functions: :constants
  def kRDSELFDIAG, do: 0x0F

  @doc functions: :constants
  def kSLPIN, do: 0x10
  @doc functions: :constants
  def kSLPOUT, do: 0x11
  @doc functions: :constants
  def kPTLON, do: 0x12
  @doc functions: :constants
  def kNORON, do: 0x13

  @doc functions: :constants
  def kINVOFF, do: 0x20
  @doc functions: :constants
  def kINVON, do: 0x21
  @doc functions: :constants
  def kGAMMASET, do: 0x26
  @doc functions: :constants
  def kDISPOFF, do: 0x28
  @doc functions: :constants
  def kDISPON, do: 0x29

  @doc functions: :constants
  def kCASET, do: 0x2A
  @doc functions: :constants
  def kPASET, do: 0x2B
  @doc functions: :constants
  def kRAMWR, do: 0x2C
  @doc functions: :constants
  def kRAMRD, do: 0x2E

  @doc functions: :constants
  def kPTLAR, do: 0x30
  @doc functions: :constants
  def kVSCRDEF, do: 0x33
  @doc functions: :constants
  def kMADCTL, do: 0x36
  @doc functions: :constants
  # Vertical Scrolling Start Address
  def kVSCRSADD, do: 0x37
  @doc functions: :constants
  def kIDLEOFF, do: 0x38
  @doc functions: :constants
  def kIDLEON, do: 0x39
  @doc functions: :constants
  # COLMOD: Pixel Format Set
  def kPIXFMT, do: 0x3A

  @doc functions: :constants
  # RGB Interface Signal Control
  def kRGB_INTERFACE, do: 0xB0
  @doc functions: :constants
  def kFRMCTR1, do: 0xB1
  @doc functions: :constants
  def kFRMCTR2, do: 0xB2
  @doc functions: :constants
  def kFRMCTR3, do: 0xB3
  @doc functions: :constants
  def kINVCTR, do: 0xB4
  # Display Function Control
  def kDFUNCTR, do: 0xB6

  @doc functions: :constants
  def kPWCTR1, do: 0xC0
  @doc functions: :constants
  def kPWCTR2, do: 0xC1
  @doc functions: :constants
  def kPWCTR3, do: 0xC2
  @doc functions: :constants
  def kPWCTR4, do: 0xC3
  @doc functions: :constants
  def kPWCTR5, do: 0xC4
  @doc functions: :constants
  def kVMCTR1, do: 0xC5
  @doc functions: :constants
  def kVMCTR2, do: 0xC7

  @doc functions: :constants
  def kRDID1, do: 0xDA
  @doc functions: :constants
  def kRDID2, do: 0xDB
  @doc functions: :constants
  def kRDID3, do: 0xDC
  @doc functions: :constants
  def kRDID4, do: 0xDD

  @doc functions: :constants
  def kGMCTRP1, do: 0xE0
  @doc functions: :constants
  def kGMCTRN1, do: 0xE1
  @doc functions: :constants
  def kDGCTR1, do: 0xE2
  @doc functions: :constants
  def kDGCTR2, do: 0xE3

  @doc functions: :constants
  def kMAD_RGB, do: 0x08
  @doc functions: :constants
  def kMAD_BGR, do: 0x00
  @doc functions: :constants
  def k18BIT_PIX, do: 0x66
  @doc functions: :constants
  def k16BIT_PIX, do: 0x55

  @doc functions: :constants
  def kMAD_VERTICAL, do: 0x20
  @doc functions: :constants
  def kMAD_X_LEFT, do: 0x00
  @doc functions: :constants
  def kMAD_X_RIGHT, do: 0x40
  @doc functions: :constants
  def kMAD_Y_UP, do: 0x80
  @doc functions: :constants
  def kMAD_Y_DOWN, do: 0x00
end
