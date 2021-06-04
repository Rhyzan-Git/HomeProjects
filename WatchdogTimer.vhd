--Notes:

--How Prescaler works
--	Prescaler determines the clock frequency. (System Clock/Desired clock)/2 = Prescaler. 
--	Convert to binary afterwards.

--Button is held causing an intial pulse to enable the watchdog pre-scaler.
--While button is held a frequent restart pulse is resetting the watchdog counter to 0
--If button is let go the restart pulses stop and when the watchdog timer hits a limit sends a shutdown signal.
--A 10ms enable pulse will be sent after button is pressed 
--Restart pulses will be sent every 1 second button is held down
--Shutdown signal will be sent 4 seconds after button is released

---------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity WatchDogTimer is
--Ports 
port (	sysClk : in std_logic;
        deadmanSwitch : in std_logic;
        shutdownLED, restartLED : out std_logic
      );
end WatchDogTimer;
architecture WatchDogTimer_behavioral of WatchDogTimer is
--Signals

--Debounce clock pre-scaler
signal Debounce_clk_prescaler : std_logic_vector (15 downto 0) := "1110101001100000";  --Turns 12Mhz into 100hz
signal Debounce_clk_prescaler_counter : std_logic_vector (15 downto 0) := (others => '0');
signal Debounce_clk : std_logic := '0';

--For Debounce Logic
signal deadmanSwitch_debounced : std_logic;			                    --Output of dead man switch debounce button
signal DMS_debounce_1, DMS_debounce_2, DMS_debounce_3 : std_logic;	--Shift Registers for DMS debounce

--Watchdog clock pre-scaler
signal wd_clk_prescaler : std_logic_vector (25 downto 0) := "10110111000110110000000000"; -- turns 12Mhz into 0.25hz(4 seconds)
signal wd_clk_prescaler_counter : std_logic_vector (25 downto 0) := (others => '0');
signal wd_clk : std_logic := '0';

begin

---------------------------------------------------------------------------------------------
--Watchdog clock
--Generates a 0.25hz clock from the 12Mhz system clock
--Used as the clock for shutdown signal
WatchTimer: process (sysClk, deadmanSwitch_debounced)
begin

if (deadmanSwitch_debounced = '1') then  
  wd_clk_prescaler_counter <= (others => '0'); --Reset condition
  elsif rising_edge(sysClk) then
    wd_clk_prescaler_counter <= wd_clk_prescaler_counter + 1;
    if (wd_clk_prescaler_counter > wd_clk_prescaler) then 
      wd_clk <= not wd_clk;
    end if;
end if;	
end process;

shutdownLED <= not wd_clk; 
restartLED <= deadmanSwitch_Debounced;   
---------------------------------------------------------------------------------------------
--Debounce clock
--Generates a 100hz clock from the 12Mhz system clock
--Used as the clock for debounce shift registers
Debounce: process (sysClk)
begin
if rising_edge(sysClk) then
	Debounce_clk_prescaler_counter <= Debounce_clk_prescaler_counter + 1;
	if (Debounce_clk_prescaler_counter > Debounce_clk_prescaler) then 
		Debounce_clk <= not Debounce_clk;
		Debounce_clk_prescaler_counter <= (others => '0');
	end if;
end if;	
end process;
---------------------------------------------------------------------------------------------
--Debounce logic
--Shift register to debounce deadmanSwitch button
Debounce_sw: process (Debounce_clk, deadmanSwitch)
begin
if rising_edge(Debounce_clk) then
	DMS_debounce_1 <= deadmanSwitch;
  DMS_debounce_2 <= DMS_debounce_1; 
	DMS_debounce_3 <= DMS_debounce_2;
end if;
end process;
--Constant '1' output while switch is held down
deadmanSwitch_debounced <= DMS_debounce_1 and DMS_debounce_2 and DMS_debounce_3;
---------------------------------------------------------------------------------------------	    
end WatchDogTimer_behavioral;
