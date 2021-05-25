--Sections for project - Based on Top Level Diagram
--NOTES:
--How Prescaler works
--	Prescaler determines the clock frequency. (System Clock/Desired clock)/2 = Prescaler. 
--	Convert to binary afterwards.
--
--Source for 8-bit LFSR 
--	https://www.engineersgarage.com/vhdl/feed-back-register-in-vhdl/
--
--LFSR will be between 62% (d20) to 78% (d100) efficent at generating a random number to pass through the filter.
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
--Ports 
port (	sysClk : in std_logic; 					--12Mhz System Clock
	Dice_LED : inout std_logic_vector (6 downto 0); 	--Used to represent currently selected dice
	Roll_Button, Select_Button : in std_logic;		--User input buttons	
	Display_7seg_LED : out std_logic_vector (7 downto 0);	--For each 7-seg display LED
	Enable_7seg : inout std_logic_vector(3 downto 0)	--Shift Register to enable 7-Seg Displays
      );
end LFSRDiceRoller;

architecture LFSRDiceRoller_behavioral of LFSRDiceRoller is

--Signals

--LFSR clock pre-scaler
--120khz Clock
--signal LFSR_clk_prescaler : std_logic_vector (5 downto 0) := "110010";
--signal LFSR_clk_prescaler_counter : std_logic_vector (5 downto 0) := (others => '0');
--2khz Clock
--signal LFSR_clk_prescaler : std_logic_vector (11 downto 0) := "101110111000";
--signal LFSR_clk_prescaler_counter : std_logic_vector (11 downto 0) := (others => '0');
--2hz Clock
signal LFSR_clk_prescaler : std_logic_vector (21 downto 0) := "1011011100011011000000";
signal LFSR_clk_prescaler_counter : std_logic_vector (21 downto 0) := (others => '0');
signal LFSR_clk : std_logic := '0';

--For LFSR Logic
signal LFSR_output: unsigned (7 DOWNTO 0);			--LFSR output signal (8-bits)		
signal LFSR_current_state : unsigned (7 downto 0) := "01011001";--Seemingly random initial condition
signal LFSR_next_state: unsigned (7 DOWNTO 0);			--LFSR states
signal LFSR_feedback: std_logic;				--LFSR XOR Feedback loop
	
--Debounce clock pre-scaler
signal Debounce_clk_prescaler : std_logic_vector (15 downto 0) := "1110101001100000";
signal Debounce_clk_prescaler_counter : std_logic_vector (15 downto 0) := (others => '0');
signal Debounce_clk : std_logic := '0';
	
--For Debounce Logic
signal Roll_button_debounced : std_logic;			--Single pulse for Roll button
signal Select_button_debounced : std_logic;			--Single pulse for Select button
signal RB_debounce_1, RB_debounce_2, RB_debounce_3 : std_logic;	--Shift Registers for Roll debounce
signal SB_debounce_1, SB_debounce_2, SB_debounce_3 : std_logic;	--Shift Registers for Select debounce

--7-Seg Display clock pre-scaler
signal Display_clk_prescaler : std_logic_vector (13 downto 0) := "11101010011000";
signal Display_clk_prescaler_counter : std_logic_vector (13 downto 0) := (others => '0');
signal Display_clk : std_logic := '0';

--For Dice Selection Logic
signal Selected_dice_output, Selected_dice_output_in : std_logic_vector(2 downto 0);
signal Selected_dice_current, Selected_dice_output_pool : std_logic_vector (2 downto 0);

--For Filter of Valid Numbers
signal dice_filter_output, LFSR_output_in: unsigned (7 downto 0) := (others => '0');							
signal Select_dice_output_in : unsigned (2 downto 0) := (others => '0');
signal dice_number_pool : std_logic_vector (7 downto 0) := (others => '0');

--For Random Number Pool logic
signal Number_pool, Number_pool_output : std_logic_vector(7 downto 0);

--For Binary to BCD Converter
signal BCD_ones, BCD_tens, BDC_hunds : std_logic_vector (3 downto 0);   --BCD output 7-seg display, rolled dice	

--For 7-seg Display shift Reg
signal Enable_7seg_select : std_logic_vector (3 downto 0) := "1110";

begin	   

---------------------------------------------------------------------------------------------
--LFSR clock
--Generates a 2khz clock from the 12Mhz system clock
--Used as the clock for the LFSR Random Number Generator
LFSR_Clock: process(sysClk)
begin
if rising_edge(sysClk) then
	LFSR_clk_prescaler_counter <= LFSR_clk_prescaler_counter + 1;
	if (LFSR_clk_prescaler_counter > LFSR_clk_prescaler) then 
		LFSR_clk <= not LFSR_clk;
	  	LFSR_clk_prescaler_counter <= (others => '0');
	end if;
end if;	
end process;
---------------------------------------------------------------------------------------------
--LFSR Random Number Ganerator (8-bit)
--Generates a random string of bits on a fast clock
--Constantly running and passing strings of bits into Filter for Valid Numbers
--LFSR State machine	
LFSR_gen: process (LFSR_clk)
begin
    if (LFSR_clk = '1' and LFSR_clk'event) then
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
--7-Seg Display clock
--Generates a 400hz clock from the 12Mhz system clock
--Used as the clock to drive each 7-seg display
Display: process (sysClk, Display_clk)
begin
if rising_edge(sysClk) then
	Display_clk_prescaler_counter <= Display_clk_prescaler_counter + 1;
	if (Display_clk_prescaler_counter > Display_clk_prescaler) then 
		Display_clk <= not Display_clk;
	  	Display_clk_prescaler_counter <= (others => '0');
	end if;
end if;
end process;
---------------------------------------------------------------------------------------------	
--Enables the 7-seg Displays
Display_en: process (Display_clk)
begin
if rising_edge(Display_clk) then
	Enable_7seg_select(1) <= Enable_7seg_select(0); 
	Enable_7seg_select(2) <= Enable_7seg_select(1); 
	Enable_7seg_select(3) <= Enable_7seg_select(2); 
	Enable_7seg_select(0) <= Enable_7seg_select(3);	
end if;
Enable_7seg <= Enable_7seg_select;
end process;

---------------------------------------------------------------------------------------------
--Debounce logic
--Shift register to debounce Roll, Select and Clear button presses
Debounce_sw: process (Debounce_clk, Roll_button, Select_button)
begin
if rising_edge(Debounce_clk) then
	RB_debounce_1 <= Roll_button;
	RB_debounce_2 <= RB_debounce_1; 
	RB_debounce_3 <= RB_debounce_2;

	SB_debounce_1 <= Select_button;
	SB_debounce_2 <= SB_debounce_1; 
	SB_debounce_3 <= SB_debounce_2;
end if;
end process;
--Single pulse sampling the first two blocks of the shift register. 
--Once the third block goes high the pulse goes low.
Roll_button_debounced <= RB_debounce_1 and RB_debounce_2 and not RB_debounce_3;
Select_button_debounced <= SB_debounce_1 and SB_debounce_2 and not SB_debounce_3;
---------------------------------------------------------------------------------------------
--Select dice button (Cycles through dice)
--	Used to select through dice (d4, d6, d8, d10, d12, d20, d100)
--	Takes pulse from Select dice button and changes selected dice
--	Interacts with 7-seg display to output selected dice
--	Interacts with Filter for Valid Numbers to change parameters
diceSelect: process (Debounce_clk, Select_button_debounced)
begin
if rising_edge (Debounce_clk) then
	if (Selected_dice_current = "111") then
		Selected_dice_current <= "000";
	elsif (Select_button_debounced = '1') then
		Selected_dice_current <= Selected_dice_current+1;
	end if;
end if;
Selected_dice_output <= Selected_dice_current;
end process;
---------------------------------------------------------------------------------------------
--Filter for Valid Numbers
--Observes numbers being generated by the 8-Bit LFSR and pulls valid numbers based on filter selected
--Passes Valid numbers to Random Number Pool       	       
filter: process (LFSR_clk, LFSR_output, Selected_dice_output)
	begin

LFSR_output_in <= LFSR_output;
Selected_dice_output_in <= Selected_dice_output;

if (LFSR_clk = '1' and LFSR_clk'event) then

--Valid d4 numbers
if (Selected_dice_output_in = "000") then
	--assigns random bits from LFSR to output, adding 1 to the result
	--fills unwanted bits with 0s
	dice_filter_output(7 downto 2) <= (others =>'0');
	--Saves LFSR number to filter (Only first 2 bits are important)
	--allows for overflow in case case of "100" '4' 
	dice_filter_output(2 downto 0) <= ('0' & LFSR_output_in(7) & LFSR_output_in(2)) + 1;     

--Valid d6 numbers
elsif (Selected_dice_output_in = "001") then
	--Checks if first 3 bits of LFSR output is between 1 and 6
	if (LFSR_output_in(3) & LFSR_output_in(7) & LFSR_output_in(5) = 7                      
   	    or LFSR_output_in(3) & LFSR_output_in(7) & LFSR_output_in(5) = 0) then
    		dice_filter_output <= dice_filter_output;
    	else 
		--Saves LFSR number to filter (Only first 3 bits are important)
    		dice_filter_output(2 downto 0) <= LFSR_output_in(3) & LFSR_output_in(7) & LFSR_output_in(5); 
		--fills unwanted bits with 0s    
		dice_filter_output(7 downto 3) <= (others =>'0'); 		
 	end if;

--Valid d8 numbers
elsif (Selected_dice_output_in = "010") then
	--assigns random bits from LFSR to output, adding 1 to the result
	--fills unwanted bits with 0s
	dice_filter_output(7 downto 3) <= (others =>'0');
	--Saves LFSR number to filter (Only first 3 bits are important)
    	--allows for overflow in case of "1000" '8'
	dice_filter_output(3 downto 0) <= ('0' & LFSR_output_in(4) & LFSR_output_in(0) & LFSR_output_in(6)) + 1;     
	       
--Valid d10 numbers
elsif (Selected_dice_output_in = "011") then
		--Ignores case of '0' output
	   if LFSR_output_in(4 downto 1)=0 then
		dice_filter_output <= dice_filter_output;
    		--Case is new number is greater than 11, fills 3-7
    	elsif (LFSR_output_in(4 downto 1)>=11 & LFSR_output_in(0) = '1' then
	       --Takes input that is greater than 11, lops off 4th bit and replaces with 0
	       	dice_filter_output(2 downto 0) <= LFSR_output_in(3 downto 1)
		dice_filter_output(7 downto 3) <= (others =>'0');
	       --case is new number is greater than 11, fills 1-2 & 8-10
	elsif (LFSR_output_in(4 downto 1)>=11 & LFSR_output_in(0) = '0' then
		   if LFSR_output_in(4 downto 1) = "1011" then 	 --if case 11
	       		dice_filter_output(3 downto 0) <= "0001" --sends 1
			dice_filter_output(7 downto 4) <= (others =>'0');
		elsif LFSR_output_in(4 downto 1) = "1100" then	 --if case 12
	    	       	dice_filter_output(3 downto 0) <= "0010" --sends 2
			dice_filter_output(7 downto 4) <= (others =>'0');
		elsif LFSR_output_in(4 downto 1) = "1101" then	 --if case 13
	    	       	dice_filter_output(3 downto 0) <= "1000" --sends 8
			dice_filter_output(7 downto 4) <= (others =>'0');
		elsif LFSR_output_in(4 downto 1) = "1110" then	 --if case 14
	    	       	dice_filter_output(3 downto 0) <= "1001" --sends 9
			dice_filter_output(7 downto 4) <= (others =>'0');
		elsif LFSR_output_in(4 downto 1) = "1111" then	 --if case 15
	    	       	dice_filter_output(3 downto 0) <= "1010" --sends 10
			dice_filter_output(7 downto 4) <= (others =>'0');
		end if;
	elsif (LFSR_output_in(4 downto 1)>=1 & LFSR_output_in(4 downto 1)<=10 then	    
		--Saves LFSR number to filter (Only first 4 bits are important)
    		dice_filter_output(3 downto 0) <= LFSR_output_in(3 downto 0);   
		--fills unwanted bits with 0s
		dice_filter_output(7 downto 4) <= (others =>'0');   
 	end if;
		
--Valid d12 numbers
elsif (Selected_dice_output_in = "100") then
	--Checks if first 4 bits of LFSR output is between 1 and 12
	if (LFSR_output_in(3 downto 0)>=13                      
    	    or LFSR_output_in(3 downto 0)=0) then
    		dice_filter_output <= dice_filter_output;
    	else 
		--Saves LFSR number to filter (Only first 4 bits are important)
    		dice_filter_output(3 downto 0) <= LFSR_output_in(3 downto 0);     
		--fills unwanted bits with 0s
		dice_filter_output(7 downto 4) <= (others =>'0'); 
 	end if;		

--Valid d20 numbers
elsif (Selected_dice_output_in = "101") then
	--Checks if first 5 bits of LFSR output is between 1 and 20
	if (LFSR_output_in(4 downto 0)>=21                      
   	    or LFSR_output_in(4 downto 0)=0) then
    		dice_filter_output <= dice_filter_output;
    	else 
		--Saves LFSR number to filter (Only first 5 bits are important)
    		dice_filter_output(4 downto 0) <= LFSR_output_in(4 downto 0);     
		--fills unwanted bits with 0s
		dice_filter_output(7 downto 5) <= (others =>'0');
 	end if;

--Valid d100 numbers
elsif (Selected_dice_output_in = "110") then
	--Checks if first 7 bits of LFSR output is between 1 and 100
	if (LFSR_output_in(6 downto 0)>=101                      
    	    or LFSR_output_in(6 downto 0)=0) then
    		dice_filter_output <= dice_filter_output;
    	else 
		--Saves LFSR number to filter (Only first 7 bits are important)
    		dice_filter_output(6 downto 0) <= LFSR_output_in(6 downto 0);     
		--fills unwanted bits with 0s
		dice_filter_output(7) <= '0';
 	end if;
end if;
end if;
end process;

dice_number_pool <= std_logic_vector(dice_filter_output);	--assigns filtered number to output pool
--Dice_LED(0) <= dice_filter_output(0);
--Dice_LED(1) <= dice_filter_output(1);
--Dice_LED(2) <= dice_filter_output(2);
--Dice_LED(3) <= dice_filter_output(3);
--Dice_LED(4) <= dice_filter_output(4);
--Dice_LED(5) <= dice_filter_output(5);
--Dice_LED(6) <= dice_filter_output(6);
---------------------------------------------------------------------------------------------
--Random Number Pool
--	Stores strings of bits based on what is currently inside the Filter of Valid Numbers
NummberPool: process(LFSR_clk, Roll_button_debounced, Selected_dice_output, dice_number_pool)
	     begin
Selected_dice_output_pool <= Selected_dice_output;

if (LFSR_clk = '1' and LFSR_clk'event) then
if (roll_button_debounced = '1') then
	   if Selected_dice_output_pool = "000" then Number_pool_output <= dice_number_pool;
	elsif Selected_dice_output_pool = "001" then Number_pool_output <= dice_number_pool;
	elsif Selected_dice_output_pool = "010" then Number_pool_output <= dice_number_pool;
	elsif Selected_dice_output_pool = "011" then Number_pool_output <= dice_number_pool;
	elsif Selected_dice_output_pool = "100" then Number_pool_output <= dice_number_pool;
	elsif Selected_dice_output_pool = "101" then Number_pool_output <= dice_number_pool;
	elsif Selected_dice_output_pool = "110" then Number_pool_output <= dice_number_pool;
	elsif Selected_dice_output_pool = "111" then Number_pool_output <= "00000000";
	end if;
end if;
end if;
end process;

Number_pool <= Number_pool_output;
---------------------------------------------------------------------------------------------
--Binary to BCD Converter
--	Convers Binary output of Number Pool to BCD to be used by 7-seg Displays       	       
BtoBCD: process (Number_pool)       
variable Number_pool_binary : std_logic_vector (7 downto 0) ;
variable BCD : std_logic_vector (11 downto 0) ;
begin
    Number_pool_binary := Number_pool;
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

end process;
---------------------------------------------------------------------------------------------
--7-Seg Display logic (Selected Dice)
--	Used to display currently selected dice
segDisp: process (Enable_7seg, selected_dice_output, BCD_ones, BCD_tens)
begin
if (Enable_7seg = "0111") then 						--Displays 10s place for Selected dice
	   if Selected_dice_output = "000" then Display_7seg_LED <= "11111111";	--d4	--Displays Blank
	elsif Selected_dice_output = "001" then Display_7seg_LED <= "11111111";	--d6	--Displays Blank
	elsif Selected_dice_output = "010" then Display_7seg_LED <= "11111111";	--d8	--Displays Blank
	elsif Selected_dice_output = "011" then Display_7seg_LED <= "11111001"; --d10	--Displays 1
	elsif Selected_dice_output = "100" then Display_7seg_LED <= "11111001"; --d12	--Displays 1
	elsif Selected_dice_output = "101" then Display_7seg_LED <= "10100100"; --d20	--Displays 2
	elsif Selected_dice_output = "110" then Display_7seg_LED <= "11000000";	--d1(00)--Displays 0
	elsif Selected_dice_output = "111" then Display_7seg_LED <= "11111111";	--Blank (Not used)
	end if;
	       
elsif (Enable_7seg = "1011") then 						--Displays 1s place for Selected Dice
	   if Selected_dice_output = "000" then Display_7seg_LED <= "10011001"; --d4	--Displays 4
	elsif Selected_dice_output = "001" then Display_7seg_LED <= "10000010"; --d6	--Displays 6
	elsif Selected_dice_output = "010" then Display_7seg_LED <= "10000000";	--d8	--Displays 8
	elsif Selected_dice_output = "011" then Display_7seg_LED <= "11000000";	--d10	--Displays 0
	elsif Selected_dice_output = "100" then Display_7seg_LED <= "10100100"; --d12	--Displays 2
	elsif Selected_dice_output = "101" then Display_7seg_LED <= "11000000";	--d20	--Displays 0
	elsif Selected_dice_output = "110" then Display_7seg_LED <= "11000000";	--d1(00)--Displays 0
	elsif Selected_dice_output = "111" then Display_7seg_LED <= "11111111";	--Blank (Not used)
	end if;
---------------------------------------------------------------------------------------------
--7-Seg Display logic (Rolled Dice)
--	Used to display Rolled dice result
--	Define 7-Seg Display logic
elsif (Enable_7seg = "1101") then 					--Displays 10s place for Rolled Dice
	   if BCD_tens = "0000" then Display_7seg_LED <= "11000000";	--Displays 0
	elsif BCD_tens = "0001" then Display_7seg_LED <= "11111001";    --Displays 1
	elsif BCD_tens = "0010" then Display_7seg_LED <= "10100100"; 	--Displays 2 
	elsif BCD_tens = "0011" then Display_7seg_LED <= "10110000"; 	--Displays 3 
	elsif BCD_tens = "0100" then Display_7seg_LED <= "10011001"; 	--Displays 4 
	elsif BCD_tens = "0101" then Display_7seg_LED <= "10010010"; 	--Displays 5 
	elsif BCD_tens = "0110" then Display_7seg_LED <= "10000010"; 	--Displays 6 
	elsif BCD_tens = "0111" then Display_7seg_LED <= "11111000"; 	--Displays 7 
	elsif BCD_tens = "1000" then Display_7seg_LED <= "10000000";	--Displays 8     
	elsif BCD_tens = "1001" then Display_7seg_LED <= "10010000"; 	--Displays 9
	end if;

elsif (Enable_7seg = "1110") then 					--Displays 1s place for Rolled Dice
	   if BCD_ones = "0000" then Display_7seg_LED <= "11000000";	--Displays 0
	elsif BCD_ones = "0001" then Display_7seg_LED <= "11111001";    --Displays 1
	elsif BCD_ones = "0010" then Display_7seg_LED <= "10100100"; 	--Displays 2 
	elsif BCD_ones = "0011" then Display_7seg_LED <= "10110000"; 	--Displays 3 
	elsif BCD_ones = "0100" then Display_7seg_LED <= "10011001"; 	--Displays 4 
	elsif BCD_ones = "0101" then Display_7seg_LED <= "10010010"; 	--Displays 5 
	elsif BCD_ones = "0110" then Display_7seg_LED <= "10000010"; 	--Displays 6 
	elsif BCD_ones = "0111" then Display_7seg_LED <= "11111000"; 	--Displays 7 
	elsif BCD_ones = "1000" then Display_7seg_LED <= "10000000";	--Displays 8     
	elsif BCD_ones = "1001" then Display_7seg_LED <= "10010000"; 	--Displays 9
	end if;
end if;
end process;
---------------------------------------------------------------------------------------------
end LFSRDiceRoller_behavioral;
