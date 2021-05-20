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
--
--Binary to BCD source https://stackoverflow.com/questions/23871792/convert-8bit-binary-number-to-bcd-in-vhdl
--
---------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity LFSRDiceRoller is
--Ports + 12Mhz system clock 
port (	sysClk : in std_logic; 					--12Mhz System Clock
	Reset : inout std_logic; 				--Used for 7-seg display driver logic
	Roll_Button,Select_Button,Clear_Button : in std_logic;	--User input buttons
      	Display_7seg_LED : out std_logic_vector (7 downto 0);	--For each 7-seg display LED
	Enable_7seg : inout std_logic_vector(3 downto 0)	--Shift Register to enable 7-Seg Displays
      );

--Signals

--LFSR clock pre-scaler
signal LFSR_clk_prescaler : std_logic_vector (11 downto 0) := "101110111000";
signal LFSR_clk_prescaler_counter : std_logic_vector (11 downto 0) := (others => '0');
signal LFSR_clk : std_logic := '0';

--For LFSR Logic
signal LFSR_output: std_logic_vector (7 DOWNTO 0);		--LFSR output signal (8-bits)		
signal LFSR_current_state, LFSR_next_state: std_logic_vector (7 DOWNTO 0);	--LFSR states
signal LFSR_feedback: std_logic;				--LFSR XOR Feedback loop
	
--Debounce clock pre-scaler
signal Debounce_clk_prescaler : std_logic_vector (15 downto 0) := "1110101001100000";
signal Debounce_clk_prescaler_counter : std_logic_vector (15 downto 0) := (others => '0');
signal Debounce_clk : std_logic := '0';
	
--For Debounce Logic
signal Roll_button_debounced : std_logic;	--Single pulse for Roll button
signal Select_button_debounced : std_logic;	--Single pulse for Select button
signal Clear_button_debounced : std_logic;	--Single pulse for Clear button
signal RB_debounce_1, RB_debounce_2, RB_debounce_3 : std_logic;	--Shift Registers for Roll debounce
signal SB_debounce_1, SB_debounce_2, SB_debounce_3 : std_logic;	--Shift Registers for Select debounce
signal CB_debounce_1, CB_debounce_2, CB_debounce_3 : std_logic;	--Shift Registers for Clear debounce

--7-Seg Display clock pre-scaler
signal Display_clk_prescaler : std_logic_vector (13 downto 0) := "11101010011000";
signal Dispaly_clk_prescaler_counter : std_logic_vector (13 downto 0) := (others => '0');
signal Display_clk : std_logic := '0';

--For Dice Selection Logic
signal Selected_dice_current, Selected_dice_next : unsigned(2 downto 0);
signal Selected_dice_output : std_logic_vector(2 downto 0);

--For Filter of Valid Numbers
signal d4_filter_output, d6_filter_output : unsigned (7 downto 0) := (others => '0');			
signal d8_filter_output, d10_filter_output : unsigned (7 downto 0) := (others => '0'); 
signal d12_filter_output, d20_filter_output  : unsigned (7 downto 0) := (others => '0');				
signal d100_filter_output, LFSR_output_in : unsigned (7 downto 0) := (others => '0');
signal d4_number_pool, d6_number_pool : std_logic_vector (7 downto 0) := (others => '0');
signal d8_number_pool, d10_number_pool : std_logic_vector (7 downto 0) := (others => '0');
signal d12_number_pool, d20_number_pool : std_logic_vector (7 downto 0) := (others => '0');
signal d100_number_pool : std_logic_vector (7 downto 0) := (others => '0');

--For Random Number Pool logic
signal Number_pool_output : std_logic_vector(7 downto 0);

end LFSRDiceRoller;

architecture LFSRDiceRoller_behavioral of LFSRDiceRoller is

begin	   

process (sysClk)

begin
---------------------------------------------------------------------------------------------
--LFSR clock
--Generates a 2khz clock from the 12Mhz system clock
--Used as the clock for the LFSR Random Number Generator
if rising_edge(sysClk) then
	LFSR_clk_prescaler_counter <= LFSR_clk_prescaler_counter + 1;
	if (LFSR_clk_prescaler_counter > LFSR_clk_prescaler) then 
		LFSR_clk <= not LFSR_clk;
	  	LFSR_clk_prescaler_counter <= (others => '0');
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
	  	Debounce_clk_prescaler_counter <= (others => '0');
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
	  	Display_clk_prescaler_counter <= (others => '0');
	end if;
end if;
	
--Enables the 7-seg Displays
if (reset = '1') then
	Enable_7seg <= "0001";
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
--Select dice button (Cycles through dice)
--	Used to select through dice (d4, d6, d8, d10, d12, d20, d100)
--	Takes pulse from Select dice button and changes selected dice
--	Interects with 7-seg display to output selected dice
--	Interects with Filter for Valid Numbers to change parameters

if (Reset = '1') then
	Selected_dice_current <= "000";
elsif rising_edge(Select_button_debounced) then
	Selected_dice_current <= Selected_dice_next;
end if;
	
 Selected_dice_next <= "000" when (Selected_dice_current=7) else
 	Selected_dice_current +1;

Selected_dice_output <= std_logic_vector(Selected_dice_current);
---------------------------------------------------------------------------------------------
--Filter for Valid Numbers
--	Observes numbers being generated by the 8-Bit LFSR and pulls valid numbers based on filter selected
--	Passes Valid numbers to Random Number Pool

--Updates LFSR numbers to be filtered
if (Reset = '1') then
	LFSR_output_in <= "00000000";
elsif rising_edge(LFSR_clk) then
	LFSR_output_in <= LFSR_output;
end if;

--Valid d4 numbers
--if Selected_dice_output = "000" then
d4_filter_output <= d4_filter_output when 
	       (LFSR_output_in(2 downto 0)>=5 or LFSR_output_in(2 downto 0)=0) else	--Checks if first 3 bits of LFSR output is between 1 and 4
	LFSR_output_in(7 downto 0);							--Saves LFSR number to filter (Only first 3 bits are important)

d4_filter_output(7 downto 3) := (others =>'0'); 					--fills unwanted bits with 0s
d4_number_pool <= std_logic_vector(d4_filter_output);					--assigns filtered number to output
--end if;

--Valid d6 numbers
--elsif Selected_dice_output = "001"
d6_filter_output <= d6_filter_output when 
	       (LFSR_output_in(2 downto 0)=7 or LFSR_output_in(2 downto 0)=0) else	--Checks if first 3 bits of LFSR output is between 1 and 6
	LFSR_output_in(7 downto 0);							--Saves LFSR number to filter (Only first 3 bits are important)

d6_filter_output(7 downto 3) := (others =>'0'); 					--fills unwanted bits with 0s
d6_number_pool <= std_logic_vector(d6_filter_output);					--assigns filtered number to output
--end if;

--Valid d8 numbers
--elsif Selected_dice_output = "010"
d8_filter_output <= d8_filter_output when 
	       (LFSR_output_in(3 downto 0)>=9 or LFSR_output_in(3 downto 0)=0) else	--Checks if first 4 bits of LFSR output is between 1 and 8
	LFSR_output_in(7 downto 0);							--Saves LFSR number to filter (Only first 4 bits are important)

d8_filter_output(7 downto 4) := (others =>'0'); 					--fills unwanted bits with 0s
d8_number_pool <= std_logic_vector(d8_filter_output);					--assigns filtered number to output
--end if;

--Valid d10 numbers
--elsif Selected_dice_output = "011"
d10_filter_output <= d10_filter_output when 
	       (LFSR_output_in(3 downto 0)>=11 or LFSR_output_in(3 downto 0)=0) else	--Checks if first 4 bits of LFSR output is between 1 and 10
	LFSR_output_in(7 downto 0);							--Saves LFSR number to filter (Only first 4 bits are important)

d10_filter_output(7 downto 4) := (others =>'0'); 					--fills unwanted bits with 0s
d10_number_pool <= std_logic_vector(d10_filter_output);					--assigns filtered number to output
--end if;

--Valid d12 numbers
--elsif Selected_dice_output = "100"
d12_filter_output <= d12_filter_output when 
	       (LFSR_output_in(3 downto 0)>=13 or LFSR_output_in(3 downto 0)=0) else	--Checks if first 4 bits of LFSR output is between 1 and 12
	LFSR_output_in(7 downto 0);							--Saves LFSR number to filter (Only first 4 bits are important)

d12_filter_output(7 downto 4) := (others =>'0'); 					--fills unwanted bits with 0s
d12_number_pool <= std_logic_vector(d12_filter_output);					--assigns filtered number to output
--end if;

--Valid d20 numbers
--elsif Selected_dice_output = "101"
d20_filter_output <= d20_filter_output when 
	       (LFSR_output_in(4 downto 0)>=21 or LFSR_output_in(4 downto 0)=0) else	--Checks if first 4 bits of LFSR output is between 1 and 10
	LFSR_output_in(7 downto 0);							--Saves LFSR number to filter (Only first 4 bits are important)

d20_filter_output(7 downto 5) := (others =>'0'); 					--fills unwanted bits with 0s
d20_number_pool <= std_logic_vector(d20_filter_output);					--assigns filtered number to output
--end if;

--Valid d100 numbers
--elsif Selected_dice_output = "110"
d100_filter_output <= d100_filter_output when 
	       (LFSR_output_in(6 downto 0)>=101 or LFSR_output_in(6 downto 0)=0) else	--Checks if first 4 bits of LFSR output is between 1 and 10
	LFSR_output_in(7 downto 0);							--Saves LFSR number to filter (Only first 4 bits are important)

d100_filter_output(7) := (others =>'0'); 						--fills unwanted bits with 0s
d100_number_pool <= std_logic_vector(d100_filter_output);				--assigns filtered number to output
--end if;     
---------------------------------------------------------------------------------------------
--Random Number Pool
--	Stores strings of bits based on what is currently inside the Filter of Valid Numbers
if rising_edge(Roll_button_debounced) then
	   if Selected_dice_output = "000" then Number_pool_output <= d4_number_pool;
	elsif Selected_dice_output = "001" then Number_pool_output <= d6_number_pool;
	elsif Selected_dice_output = "010" then Number_pool_output <= d8_number_pool;
	elsif Selected_dice_output = "111" then Number_pool_output <= d10_number_pool;
	elsif Selected_dice_output = "101" then Number_pool_output <= d12_number_pool;
	elsif Selected_dice_output = "101" then Number_pool_output <= d20_number_pool;
	elsif Selected_dice_output = "110" then Number_pool_output <= d100_number_pool;
	elsif Selected_dice_output = "111" then Number_pool_output <= "00000000";
	end if;
end if;
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
--Binary to BCD Converter
--	Convers Binary output of Number Pool to BCD to be used by 7-seg Displays

process ( Number_pool_output )
    variable Number_pool_binary : std_logic_vector (7 downto 0) ;
    variable BCD : std_logic_vector (11 downto 0) ;
begin
    Number_pool_binary := Number_pool_output;
    BCD := (others => '0') ;

    for i in 0 to 7 loop
        if BCD(3 downto 0) > "0100" then
            BCD(3 downto 0) := BCD(3 downto 0) + "0011" ;
        end if ;
        if BCD(7 downto 4) > "0100" then
            BCD(7 downto 4) := BCD(7 downto 4) + "0011" ;
        end if ;
        if BCD(11 downto 8) > "0100" then
            BCD(11 downto 8) := BCD(11 downto 8) + "0011" ;
        end if ;

        BCD := BCD(10 downto 0) & Number_pool_binary(7) ; -- shift bcd + 1 new entry
        Number_pool_binary := Number_pool_binary(6 downto 0) & '0' ; -- shift src + pad with 0
    end loop ;

    BDC_hunds <= BCD(11 downto 8) ;		--Not used
    BCD_tens <= BCD(7  downto 4) ;		--Displays tens place
    BCD_ones <= BCD(3  downto 0) ;		--Displays ones place

end process ;
---------------------------------------------------------------------------------------------
--7-Seg Display logic (Selected Dice)
--	Used to display currently selected dice
if (Enable_7seg = "1000") then 						--Displays 10s place for Selected dice
	   if Selected_dice_output = "000" then Display_7seg_LED <= "0000000";	--d4	--Displays Blank
	elsif Selected_dice_output = "001" then Display_7seg_LED <= "0000000";	--d6	--Displays Blank
	elsif Selected_dice_output = "010" then Display_7seg_LED <= "0000000"; 	--d8	--Displays Blank
	elsif Selected_dice_output = "011" then Display_7seg_LED <= "0000110"; 	--d10	--Displays 1
	elsif Selected_dice_output = "100" then Display_7seg_LED <= "0000110"; 	--d12	--Displays 1
	elsif Selected_dice_output = "101" then Display_7seg_LED <= "1011011"; 	--d20	--Displays 2
	elsif Selected_dice_output = "110" then Display_7seg_LED <= "0111111"; 	--d1(00)--Displays 0
	elsif Selected_dice_output = "111" then Display_7seg_LED <= "0000000"; 	--Blank (Not used)
	end if;
	       
elsif (Enable_7seg = "0100") then 						--Displays 1s place for Selected Dice
	   if Selected_dice_output = "000" then Display_7seg_LED <= "1100110";	--d4	--Displays 4
	elsif Selected_dice_output = "001" then Display_7seg_LED <= "1111101";	--d6	--Displays 6
	elsif Selected_dice_output = "010" then Display_7seg_LED <= "1111111"; 	--d8	--Displays 8
	elsif Selected_dice_output = "011" then Display_7seg_LED <= "0111111"; 	--d10	--Displays 0
	elsif Selected_dice_output = "100" then Display_7seg_LED <= "1011011"; 	--d12	--Displays 2
	elsif Selected_dice_output = "101" then Display_7seg_LED <= "0111111"; 	--d20	--Displays 0
	elsif Selected_dice_output = "110" then Display_7seg_LED <= "0111111"; 	--d1(00)--Displays 0
	elsif Selected_dice_output = "111" then Display_7seg_LED <= "0000000"; 	--Blank (Not used)
	end if;
---------------------------------------------------------------------------------------------
--7-Seg Display logic (Rolled Dice)
--	Used to display Rolled dice result
--	Define 7-Seg Display logic

elsif (Enable_7seg = "0010") then 						--Displays 10s place for Rolled Dice
	   if BCD_tens = "0000" then Display_7seg_LED <= "0111111";		--Displays 0
	elsif BCD_tens = "0001" then Display_7seg_LED <= "0000110";		--Displays 1
	elsif BCD_tens = "0010" then Display_7seg_LED <= "1011011";     	--Displays 2 
	elsif BCD_tens = "0011" then Display_7seg_LED <= "1001111"; 		--Displays 3 
	elsif BCD_tens = "0100" then Display_7seg_LED <= "1100110"; 		--Displays 4 
	elsif BCD_tens = "0101" then Display_7seg_LED <= "1101101"; 		--Displays 5 
	elsif BCD_tens = "0110" then Display_7seg_LED <= "1111101"; 		--Displays 6 
	elsif BCD_tens = "0111" then Display_7seg_LED <= "0000111"; 		--Displays 7 
	elsif BCD_tens = "1000" then Display_7seg_LED <= "1111111";		--Displays 8     
	elsif BCD_tens = "1001" then Display_7seg_LED <= "1101111"; 		--Displays 9
	end if;

elsif (Enable_7seg = "0001") then 						--Displays 1s place for Rolled Dice
	   if BCD_ones = "0000" then Display_7seg_LED <= "0111111";		--Displays 0
	elsif BCD_ones = "0001" then Display_7seg_LED <= "0000110";     	--Displays 1
	elsif BCD_ones = "0010" then Display_7seg_LED <= "1011011";     	--Displays 2 
	elsif BCD_ones = "0011" then Display_7seg_LED <= "1001111"; 		--Displays 3 
	elsif BCD_ones = "0100" then Display_7seg_LED <= "1100110"; 		--Displays 4 
	elsif BCD_ones = "0101" then Display_7seg_LED <= "1101101"; 		--Displays 5 
	elsif BCD_ones = "0110" then Display_7seg_LED <= "1111101"; 		--Displays 6 
	elsif BCD_ones = "0111" then Display_7seg_LED <= "0000111"; 		--Displays 7 
	elsif BCD_ones = "1000" then Display_7seg_LED <= "1111111";		--Displays 8     
	elsif BCD_ones = "1001" then Display_7seg_LED <= "1101111";    	 	--Displays 9
	end if;
end if;
---------------------------------------------------------------------------------------------
end process;

end LFSRDiceRoller_behavioral;
