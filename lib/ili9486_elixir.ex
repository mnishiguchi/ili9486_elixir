defmodule ILI9486 do
  @moduledoc """
  ILI9486 Elixir driver
  """

  @doc false
  def kNOP, do: 0x00
  def kSWRESET, do: 0x01

  def kRDDID, do: 0x04
  def kRDDST, do: 0x09
  def kRDMODE, do: 0x0A
  def kRDMADCTL, do: 0x0B
  def kRDPIXFMT, do: 0x0C
  def kRDIMGFMT, do: 0x0D
  def kRDSELFDIAG, do: 0x0F

  def kSLPIN, do: 0x10
  def kSLPOUT, do: 0x11
  def kPTLON, do: 0x12
  def kNORON, do: 0x13

  def kINVOFF, do: 0x20
  def kINVON, do: 0x21
  def kGAMMASET, do: 0x26
  def kDISPOFF, do: 0x28
  def kDISPON, do: 0x29

  def kCASET, do: 0x2A
  def kPASET, do: 0x2B
  def kRAMWR, do: 0x2C
  def kRAMRD, do: 0x2E

  def kPTLAR, do: 0x30
  def kVSCRDEF, do: 0x33
  def kMADCTL, do: 0x36
  # Vertical Scrolling Start Address
  def kVSCRSADD, do: 0x37
  # COLMOD: Pixel Format Set
  def kPIXFMT, do: 0x3A

  # RGB Interface Signal Control
  def kRGB_INTERFACE, do: 0xB0
  def kFRMCTR1, do: 0xB1
  def kFRMCTR2, do: 0xB2
  def kFRMCTR3, do: 0xB3
  def kINVCTR, do: 0xB4
  # Display Function Control
  def kDFUNCTR, do: 0xB6

  def kPWCTR1, do: 0xC0
  def kPWCTR2, do: 0xC1
  def kPWCTR3, do: 0xC2
  def kPWCTR4, do: 0xC3
  def kPWCTR5, do: 0xC4
  def kVMCTR1, do: 0xC5
  def kVMCTR2, do: 0xC7

  def kRDID1, do: 0xDA
  def kRDID2, do: 0xDB
  def kRDID3, do: 0xDC
  def kRDID4, do: 0xDD

  def kGMCTRP1, do: 0xE0
  def kGMCTRN1, do: 0xE1
  def kDGCTR1, do: 0xE2
  def kDGCTR2, do: 0xE3

  def kMAD_RGB, do: 0x08
  def kMAD_BGR, do: 0x00

  def kMAD_VERTICAL, do: 0x20
  def kMAD_X_LEFT, do: 0x00
  def kMAD_X_RIGHT, do: 0x40
  def kMAD_Y_UP, do: 0x80
  def kMAD_Y_DOWN, do: 0x00
end
