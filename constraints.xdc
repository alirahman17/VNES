set_property IOSTANDARD LVCMOS33 [get_ports {clk}]
set_property PACKAGE_PIN Y9 [get_ports {clk}]
create_clock -period 10 [get_ports {clk}]

# ----------------------------------------------------------------------------
# Clock Source - Bank 13
# ---------------------------------------------------------------------------- 
# set_property PACKAGE_PIN Y9 [get_ports {GCLK}];  # "GCLK"

# ----------------------------------------------------------------------------
# JA Pmod - Bank 13 
# ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN Y11  [get_ports {JA1}];  # "JA1"
#set_property PACKAGE_PIN AA8  [get_ports {JA10}];  # "JA10"
#set_property PACKAGE_PIN AA11 [get_ports {JA2}];  # "JA2"
#set_property PACKAGE_PIN Y10  [get_ports {JA3}];  # "JA3"
#set_property PACKAGE_PIN AA9  [get_ports {JA4}];  # "JA4"
#set_property PACKAGE_PIN AB11 [get_ports {JA7}];  # "JA7"
#set_property PACKAGE_PIN AB10 [get_ports {JA8}];  # "JA8"
#set_property PACKAGE_PIN AB9  [get_ports {JA9}];  # "JA9"


# ----------------------------------------------------------------------------
# JB Pmod - Bank 13
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN W12 [get_ports {NES_JOYPAD_CLK}];  # "JB1"
set_property PACKAGE_PIN W11 [get_ports {NES_JOYPAD_LATCH}];  # "JB2"
set_property PACKAGE_PIN V10 [get_ports {NES_JOYPAD_DATA1}];  # "JB3"
set_property PACKAGE_PIN W8 [get_ports {NES_JOYPAD_DATA2}];  # "JB4"
#set_property PACKAGE_PIN V12 [get_ports {JB7}];  # "JB7"
#set_property PACKAGE_PIN W10 [get_ports {JB8}];  # "JB8"
#set_property PACKAGE_PIN V9 [get_ports {JB9}];  # "JB9"
#set_property PACKAGE_PIN V8 [get_ports {JB10}];  # "JB10"

# ----------------------------------------------------------------------------
# JC Pmod - Bank 13
# ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN AB6 [get_ports {JC1_N}];  # "JC1_N"
#set_property PACKAGE_PIN AB7 [get_ports {JC1_P}];  # "JC1_P"
#set_property PACKAGE_PIN AA4 [get_ports {JC2_N}];  # "JC2_N"
#set_property PACKAGE_PIN Y4  [get_ports {JC2_P}];  # "JC2_P"
#set_property PACKAGE_PIN T6  [get_ports {JC3_N}];  # "JC3_N"
#set_property PACKAGE_PIN R6  [get_ports {JC3_P}];  # "JC3_P"
#set_property PACKAGE_PIN U4  [get_ports {JC4_N}];  # "JC4_N"
#set_property PACKAGE_PIN T4  [get_ports {JC4_P}];  # "JC4_P"

# ----------------------------------------------------------------------------
# JD Pmod - Bank 13
# ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN W7 [get_ports {JD1_N}];  # "JD1_N"
#set_property PACKAGE_PIN V7 [get_ports {JD1_P}];  # "JD1_P"
#set_property PACKAGE_PIN V4 [get_ports {JD2_N}];  # "JD2_N"
#set_property PACKAGE_PIN V5 [get_ports {JD2_P}];  # "JD2_P"
#set_property PACKAGE_PIN W5 [get_ports {JD3_N}];  # "JD3_N"
#set_property PACKAGE_PIN W6 [get_ports {JD3_P}];  # "JD3_P"
#set_property PACKAGE_PIN U5 [get_ports {JD4_N}];  # "JD4_N"
#set_property PACKAGE_PIN U6 [get_ports {JD4_P}];  # "JD4_P"


# ----------------------------------------------------------------------------
# User LEDs - Bank 33
# ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN T22 [get_ports {LD0}];  # "LD0"
#set_property PACKAGE_PIN T21 [get_ports {LD1}];  # "LD1"
#set_property PACKAGE_PIN U22 [get_ports {LD2}];  # "LD2"
#set_property PACKAGE_PIN U21 [get_ports {LD3}];  # "LD3"
#set_property PACKAGE_PIN V22 [get_ports {LD4}];  # "LD4"
#set_property PACKAGE_PIN W22 [get_ports {LD5}];  # "LD5"
#set_property PACKAGE_PIN U19 [get_ports {LD6}];  # "LD6"
#set_property PACKAGE_PIN U14 [get_ports {LD7}];  # "LD7"

# ----------------------------------------------------------------------------
# VGA Output - Bank 33
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN AA19  [get_ports {VGA_HSYNC}];  # "VGA-B1"
set_property PACKAGE_PIN Y19  [get_ports {VGA_VSYNC];  # "VGA-B2"
set_property PACKAGE_PIN V18 [get_ports {VGA_RED<0>}];  # "VGA-B3"
set_property PACKAGE_PIN V19 [get_ports {VGA_RED<1>}];  # "VGA-B4"
set_property PACKAGE_PIN U20 [get_ports {VGA_RED<2>}];  # "VGA-G1"
set_property PACKAGE_PIN AA21 [get_ports {VGA_GREEN<0>}];  # "VGA-G2"
set_property PACKAGE_PIN AB21 [get_ports {VGA_GREEN<1>}];  # "VGA-G3"
set_property PACKAGE_PIN AA22 [get_ports {VGA_GREEN<2>}];  # "VGA-G4"
set_property PACKAGE_PIN AB19 [get_ports {VGA_BLUE<0>}];  # "VGA-HS"
set_property PACKAGE_PIN AB20  [get_ports {VGA_BLUE<1>}];  # "VGA-R1"
s#et_property PACKAGE_PIN U20  [get_ports {VGA_BLUE<2>}];  # "VGA-R2"
#set_property PACKAGE_PIN V19  [get_ports {VGA_R3}];  # "VGA-R3"
#set_property PACKAGE_PIN V18  [get_ports {VGA_R4}];  # "VGA-R4"
#set_property PACKAGE_PIN Y19  [get_ports {VGA_VS}];  # "VGA-VS"

# ----------------------------------------------------------------------------
# User Push Buttons - Bank 34
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN P16 [get_ports {BTN_SOUTH}];  # "BTNC"
set_property PACKAGE_PIN R16 [get_ports {BTN_EAST}];  # "BTND"
#set_property PACKAGE_PIN N15 [get_ports {BTNL}];  # "BTNL"
#set_property PACKAGE_PIN R18 [get_ports {BTNR}];  # "BTNR"
#set_property PACKAGE_PIN T18 [get_ports {BTNU}];  # "BTNU"

# ----------------------------------------------------------------------------
# USB OTG Reset - Bank 34
# ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN L16 [get_ports {OTG_VBUSOC}];  # "OTG-VBUSOC"

# ----------------------------------------------------------------------------
# XADC GIO - Bank 34
# ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN H15 [get_ports {XADC_GIO0}];  # "XADC-GIO0"
#set_property PACKAGE_PIN R15 [get_ports {XADC_GIO1}];  # "XADC-GIO1"
#set_property PACKAGE_PIN K15 [get_ports {XADC_GIO2}];  # "XADC-GIO2"
#set_property PACKAGE_PIN J15 [get_ports {XADC_GIO3}];  # "XADC-GIO3"

# ----------------------------------------------------------------------------
# Miscellaneous - Bank 34
# ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN K16 [get_ports {PUDC_B}];  # "PUDC_B"

## ----------------------------------------------------------------------------
## USB OTG Reset - Bank 35
## ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN G17 [get_ports {OTG_RESETN}];  # "OTG-RESETN"

## ----------------------------------------------------------------------------
## User DIP Switches - Bank 35
## ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN F22 [get_ports {SW0}];  # "SW0"
set_property PACKAGE_PIN G22 [get_ports {SW1}];  # "SW1"
set_property PACKAGE_PIN H22 [get_ports {SW2}];  # "SW2"
set_property PACKAGE_PIN F21 [get_ports {SW3}];  # "SW3"
#set_property PACKAGE_PIN H19 [get_ports {SW4}];  # "SW4"
#set_property PACKAGE_PIN H18 [get_ports {SW5}];  # "SW5"
#set_property PACKAGE_PIN H17 [get_ports {SW6}];  # "SW6"
#set_property PACKAGE_PIN M15 [get_ports {SW7}];  # "SW7"

## ----------------------------------------------------------------------------
## XADC AD Channels - Bank 35
## ---------------------------------------------------------------------------- 
#set_property PACKAGE_PIN E16 [get_ports {AD0N_R}];  # "XADC-AD0N-R"
#set_property PACKAGE_PIN F16 [get_ports {AD0P_R}];  # "XADC-AD0P-R"
#set_property PACKAGE_PIN D17 [get_ports {AD8N_N}];  # "XADC-AD8N-R"
#set_property PACKAGE_PIN D16 [get_ports {AD8P_R}];  # "XADC-AD8P-R"

# Note that the bank voltage for IO Bank 33 is fixed to 3.3V on ZedBoard. 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];

# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 34]];
# set_property IOSTANDARD LVCMOS25 [get_ports -of_objects [get_iobanks 34]];
#set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];

# Set the bank voltage for IO Bank 35 to 1.8V by default.
 set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 35]];
# set_property IOSTANDARD LVCMOS25 [get_ports -of_objects [get_iobanks 35]];
# set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];

# Note that the bank voltage for IO Bank 13 is fixed to 3.3V on ZedBoard. 
 set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];