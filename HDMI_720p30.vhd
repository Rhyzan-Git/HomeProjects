--Notes:
--HDMI TMDS uses 3.3v signals
--Test output freq with MMCM or PLL, scope has a max of 200Mhz, try and generate a 100MHZ diff signal on ioPins
  --Pixel Clock - 37.125Mhz - Need to make use of PLL
  --TMDS Clock - 371.25Mhz - Need to make use of PLL
https://forums.xilinx.com/t5/Other-FPGA-Architecture/Using-TMDS-for-a-point-to-point-link/td-p/880514

Pixel color Data

Encoded sound

Timing & aux data



1280x720p 30 
Pixel Clock 37.125Mhz
TMDS Clock 371.25Mhz





    Pixel Clock       74.250 MHz
    TMDS Clock       742.500 MHz
    Pixel Time          13.5 ns ±0.5%
    Horizontal Freq.  45.000 kHz
    Line Time           22.2 μs
    Vertical Freq.    60.000 Hz
    Frame Time          16.7 ms

    Horizontal Timings
    Active Pixels       1280
    Front Porch          110
    Sync Width            40
    Back Porch           220
    Blanking Total       370
    Total Pixels        1650
    Sync Polarity        pos

    Vertical Timings
    Active Lines         720
    Front Porch            5
    Sync Width             5
    Back Porch            20
    Blanking Total        30
    Total Lines          750
    Sync Polarity        pos

    Active Pixels    921,600
    Data Rate           1.78 Gbps

    Frame Memory (Kbits)
     8-bit Memory      7,200
    12-bit Memory     10,800
    24-bit Memory     21,600 
    32-bit Memory     28,800
