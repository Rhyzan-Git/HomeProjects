--Sections for project - Based on Top Level Diagram
--NOTES:
--How Prescaler works
--	Prescaler determines the clock frequency. (System Clock/Desired clock)/2 = Prescaler. 
--	Convert to binary afterwards.
--
--Source for 8-bit LFSR 
--	https://www.engineersgarage.com/vhdl/feed-back-register-in-vhdl/
--
--LFSR will be between 50% (d8) to 78% (d100) efficent at generating a random number to pass through the filter.
--	With a 2khz clock that means on average a new number will be generated every 0.625ms to 1ms. 

---------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;

entity LFSRDiceRoller is
--Ports + 12Mhz system clock 
port (	sysClk : in std:logic; 					--12Mhz System Clock
	Reset : inout std_ logic; 				--Used for 7-seg display driver logic
	Roll_Button,Select_Button,Clear_Button : in std_logic;	--User input buttons
	Enable_7seg : inout std_logic_vector(3 downto 0)	--Shift Register to enable 7-Seg Displays
      );
end LFSRDiceRoller;

architecture LFSRDiceRoller_behavioral of LFSRDiceRoller is

--Signals

--LFSR clock pre-scaler
signal LFSR_clk_prescaler : std_logic_vector (11 downto 0) := “101110111000”;
signal LFSR_clk_prescaler_counter : std_logic_vector (11 downto 0) := (others => ‘0’);
signal LFSR_clk : std_logic := ‘0’;

--For LFSR Logic
signal LFSR_output: out std_logic_vector (7 DOWNTO 0);		--LFSR output signal (8-bits)		
signal LFSR_current_state, LFSR_next_state: std_logic_vector (7 DOWNTO 0);	--LFSR states
signal LFSR_feedback: std_logic;				--LFSR XOR Feedback loop
	
--Debounce clock pre-scaler
signal Debounce_clk_prescaler : std_logic_vector (15 downto 0) := “1110101001100000”;
signal Debounce_clk_prescaler_counter : std_logic_vector (15 downto 0) := (others => ‘0’);
signal Debounce_clk : std_logic := ‘0’;
	
--For Debounce Logic
signal Roll_button_debounced : std_logic;	--Single pulse for Roll button
signal Select_button_debounced : std_logic;	--Single pulse for Select button
signal Clear_button_debounced : std_logic;	--Single pulse for Clear button
signal RB_debounce_1, RB_debounce_2, RB_debounce_3 : std_logic;	--Shift Registers for Roll debounce
signal SB_debounce_1, SB_debounce_2, SB_debounce_3 : std_logic;	--Shift Registers for Select debounce
signal CB_debounce_1, CB_debounce_2, CB_debounce_3 : std_logic;	--Shift Registers for Clear debounce

--7-Seg Display clock pre-scaler
signal Display_clk_prescaler : std_logic_vector (13 downto 0) := “11101010011000”;
signal Dispaly_clk_prescaler_counter : std_logic_vector (13 downto 0) := (others => ‘0’);
signal Display_clk : std_logic := ‘0’;

begin	   
---------------------------------------------------------------------------------------------
--LFSR clock
--Generates a 2khz clock from the 12Mhz system clock
--Used as the clock for the LFSR Random Number Generator
if rising_edge(sysClk) then
	LFSR_clk_prescaler_counter <= LFSR_clk_prescaler_counter + 1;
	if (LFSR_clk_prescaler_counter > LFSR_clk_prescaler) then 
		LFSR_clk <= not LFSR_clk;
	  	LFSR_clk_prescaler_counter <= (others => ‘0’);
	end if;
end if;	
---------------------------------------------------------------------------------------------
--LFSR Random Number Ganerator (8-bit)
--Generates a random string of bits on a fast clock
--Constantly running and passing strings of bits into Filter for Valid Numbers
--LFSR State machine	
StateReg: process (LFSR_clk, Reset)
	if (Reset = '1') then
		LFSR_current_state <= (0 => '1', others =>'0');
    	elsif (LFSR_clk = '1' and LFSR_clk'event) then
	       LFSR_current_state <= LFSR_next_state;
   	end if;
end process;

--Generates new psuedorandom number
LFSR_feedback <= LFSR_current_state(4) XOR LFSR_current_state(3) XOR LFSR_current_state(2) XOR LFSR_current_state(0); 	

--Stores new psuedorandom number
LFSR_next_state <= LFSR_feedback & LFSR_current_state(7 DOWNTO 1);							

--Outputs current psuedorandom number
LFSR_output <= LFSR_current_state;											
---------------------------------------------------------------------------------------------
--Debounce clock
--Generates a 100hz clock from the 12Mhz system clock
--Used as the clock for debounce shift registers
if rising_edge(sysClk) then
	Debounce_clk_prescaler_counter <= Debounce_clk_prescaler_counter + 1;
	if (Debounce_clk_prescaler_counter > Debounce_clk_prescaler) then 
		Debounce_clk <= not Debounce_clk;
	  	Debounce_clk_prescaler_counter <= (others => ‘0’);
	end if;
end if;	
---------------------------------------------------------------------------------------------	
--7-Seg Display clock
--Generates a 400hz clock from the 12Mhz system clock
--Used as the clock to drive each 7-seg display
if rising_edge(sysClk) then
	Display_clk_prescaler_counter <= Display_clk_prescaler_counter + 1;
	if (Display_clk_prescaler_counter > Display_clk_prescaler) then 
		Display_clk <= not Display_clk;
	  	Display_clk_prescaler_counter <= (others => ‘0’);
	end if;
end if;
	
--Enables the 7-seg Displays
if (reset = ‘1’) then
	Enable_7seg <= “0001”;
elsif rising_edge(Display_clk) then
	Enable_7seg(1) <= Enable_7seg(0); Enable_7seg(2) <= Enable_7seg(1); 
	Enable_7seg(3) <= Enable_7seg(2); Enable_7seg(0) <= Enable_7seg(3);	
end if;
---------------------------------------------------------------------------------------------
--Debounce logic
--Shift register to debounce Roll, Select and Clear button presses
if rising_edge(Debounce_clk) then
	RB_debounce_1 <= Roll_button;
	RB_debounce_2 <= RB_debounce_1; 
	RB_debounce_3 <= RB_debounce_2;

	SB_debounce_1 <= Select_button;
	SB_debounce_2 <= SB_debounce_1; 
	SB_debounce_3 <= SB_debounce_2;

	CB_debounce_1 <= Clear_button;
	CB_debounce_2 <= CB_debounce_1; 
	CB_debounce_3 <= CB_debounce_2;
end if;

--Single pulse sampling the first two blocks of the shift register. Once the third block goes high the pulse goes low.
Roll_button_debounced <= RB_debounce_1 and RB_debounce_2 and not RB_debounce_3;
Select_button_debounced <= SB_debounce_1 and SB_debounce_2 and not SB_debounce_3;
Clear_button_debounced <= CB_debounce_1 and CB_debounce_2 and not CB_debounce_3;
---------------------------------------------------------------------------------------------
--Roll dice button (Hold)
--	Used to hold the current string of bits in the Random Number Pool
--	Define Roll dice button logic

---------------------------------------------------------------------------------------------
--Clear roll dice button (Reset)
--	Used to clear the current string of bits in the Random Number Pool
--	Used to enable the Random Number Pool to start accepting new strings of bits
--	Define Clear roll dice button logic

---------------------------------------------------------------------------------------------
--Select dice button (Cycles through dice)
--	Used to select through dice (d4, d6, d8, d10, d12, d20, d100)
--	Define Select dice button logic

signal Selected_dice_BCD : std_logic_vector(2 downto 0) := (others => ‘0’);
if (Reset = '1') then
	Selected_dice_BCD <= “000”;
elsif rising_edge(Select_button_debounced) then
	Selected_dice_current <= Selected_dice_next;
end if;
	
Selected    <= "0000"     WHEN (d1Curr=9) ELSE
              d1Curr+1;



---------------------------------------------------------------------------------------------
--Switching dice logic
--	Takes pulse from Select dice button and changes selected dice
--	Interects with 7-seg display to output selected dice
--	Interects with Filter for Valid Numbers to change parameters
--	Define Switching dice logic



---------------------------------------------------------------------------------------------
--Filter for Valid Numbers
--	Observes numbers being generated by the 8-Bit LFSR and pulls valid numbers based on filter selected
--	Passes Valid numbers to Random Number Pool
--	Define Filter for Valid Numbers logic

---------------------------------------------------------------------------------------------
--Random Number Pool
--	Stores strings of bits based on what is currently inside the Filter of Valid Numbers
--	Define Random Number Pool logic

---------------------------------------------------------------------------------------------
--7-Seg Display logic (Selected Dice)
--	Used to display currently selected dice
--	Define 7-Seg Display logic


	       
if (Enable_7seg = "1000") then 						--Displays 10s place for Selected Dice







    if Dice_1s = “0000” then Display_7seg_LED <= "0111111";		--Displays 0
    elsif Dice_1s = “0001” then Display_7seg_LED <= "0000110";		--Displays 1
    elsif Dice_1s = “0010” then Display_7seg_LED <= "1011011"; 		--Displays 2 
    elsif Dice_1s = “0011” then Display_7seg_LED <= "1001111"; 		--Displays 3 
    elsif Dice_1s = “0100” then Display_7seg_LED <= "1100110"; 		--Displays 4 
    elsif Dice_1s = “0101” then Display_7seg_LED <= "1101101"; 		--Displays 5 
    elsif Dice_1s = “0110” then Display_7seg_LED <= "1111101"; 		--Displays 6 
    elsif Dice_1s = “0111” then Display_7seg_LED <= "0000111"; 		--Displays 7 
    elsif Dice_1s = “1000” then Display_7seg_LED <= "1111111";		--Displays 8     
    elsif Dice_1s = “1001” then Display_7seg_LED <= "1101111"; 		--Displays 9

if (Enable_7seg = "0100") then 						--Displays 1s place for Selected dice

---------------------------------------------------------------------------------------------
--7-Seg Display logic (Rolled Dice)
--	Used to display Rolled dice result
--	Define 7-Seg Display logic

---------------------------------------------------------------------------------------------


-- Anything below here is not used
entity D20_Roller is
    Port(
Roll_button : in std:logic;

Display_7seg_LED : out std_logic_vector(6 downto 0);

);

Signal Roll_button_debounced, Debounce_1, Debounce_2, Debounce_3 : std_logic;
Signal Pause : std_logic;
Signal Dice_side : std_logic_vector(19 downto 0);
Signal Roll : std_logic_vector(19 downto 0);
Signal Dice_1s : std_logic_vector(1 downto 0);
Signal Dice_10s : std_logic_vector(3 downto 0);




--User input


--Starts pause condition if roll button is pressed
Pause <= Roll_button_debounced or (Pause and not Reset);

--Sets roll value after clock is paused
If (Pause = "1") then
Roll <= Dice_side;
End if;

--Back-end

If (reset = ‘1’) then
Dice_side <= “00000000000000000001”;
elsif rising_edge(Roller_clk) then
Dice_side(1) <= Dice_side(0); Dice_side(2) <= Dice_side(1); 
Dice_side(3) <= Dice_side(2); Dice_side(4) <= Dice_side(3);
Dice_side(5) <= Dice_side(4); Dice_side(6) <= Dice_side(5);
Dice_side(7) <= Dice_side(6); Dice_side(8) <= Dice_side(7);
Dice_side(9) <= Dice_side(8); Dice_side(10) <= Dice_side(9);
Dice_side(11) <= Dice_side(10); Dice_side(12) <= Dice_side(11);
Dice_side(13) <= Dice_side(12); Dice_side(14) <= Dice_side(13);
Dice_side(15) <= Dice_side(14); Dice_side(16) <= Dice_side(15);
Dice_side(17) <= Dice_side(16); Dice_side(18) <= Dice_side(17);
Dice_side(19) <= Dice_side(18); Dice_side(0) <= Dice_side(19);
End if;


    If (Roll = "00000000000000000001") then Dice_10s <= “01”; Dice_1s <= "0011" ;	--13
elsif (Roll = "00000000000000000010") then Dice_10s <= “01”; Dice_1s <= "0111" ;	--17
elsif (Roll = "00000000000000000100") then Dice_10s <= “01”; Dice_1s <= "1001" ;	--19
elsif (Roll = "00000000000000001000") then Dice_10s <= “00”; Dice_1s <= "1001" ;	--9
elsif (Roll = "00000000000000010000") then Dice_10s <= “00”; Dice_1s <= "0110" ;	--6
elsif (Roll = "00000000000000100000") then Dice_10s <= “00”; Dice_1s <= "0001" ;        --1
elsif (Roll = "00000000000001000000") then Dice_10s <= “00”; Dice_1s <= "1000" ;	--8
elsif (Roll = "00000000000010000000") then Dice_10s <= “01”; Dice_1s <= "1000" ;	--18
elsif (Roll = "00000000000100000000") then Dice_10s <= “00”; Dice_1s <= "0010" ;	--2
elsif (Roll = "00000000001000000000") then Dice_10s <= “00”; Dice_1s <=  "0101" 	--5
elsif (Roll = "00000000010000000000") then Dice_10s <= “00”; Dice_1s <= "0111" ;	--7
elsif (Roll = "00000000100000000000") then Dice_10s <= “01”; Dice_1s <= "0110" ;	--16
elsif (Roll = "00000001000000000000") then Dice_10s <= “00”; Dice_1s <= "0011" ;	--3
elsif (Roll = "00000010000000000000") then Dice_10s <= “01”; Dice_1s <= "0000" ;	--10
elsif (Roll = "00000100000000000000") then Dice_10s <= “00”; Dice_1s <= "0100" ;	--4
elsif (Roll = "00001000000000000000") then Dice_10s <= “10”; Dice_1s <= "0000" ;	--20
elsif (Roll = "00010000000000000000") then Dice_10s <= “01”; Dice_1s <= "0010" ;	--12
elsif (Roll = "00100000000000000000") then Dice_10s <= “01”; Dice_1s <= "0100" ;	--14
elsif (Roll = "01000000000000000000") then Dice_10s <= “01”; Dice_1s <= "0101" ;	--15
elsif (Roll = "10000000000000000000") then Dice_10s <= “01”; Dice_1s <= "0001" ;	--11
End if;






--User output


 if (AN_7seg = "0010") then 					--Displays 10s place
    if Dice_10s = “00” then Display_7seg_LED <= "0111111";	--Displays 0
    elsif Dice_10s = “01” then Display_7seg_LED <= "0000110";	--Displays 1
    elsif Dice_10s = “10” then Display_7seg_LED <= "1011011"; 	--Displays 2
    end if;
end if;
	
end process;
end behavioral;
