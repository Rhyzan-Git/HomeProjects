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
library machxo2;
use machxo2.all;
library ieee;
use ieee.std_logic_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity LFSRDiceRoller is
--Ports 
port (	--sysClk : inout std_logic; 								--12Mhz System Clock
		--Roll_Button, Select_Button : in std_logic;			--User input buttons	
		--Display_7seg_LED : out std_logic_vector (6 downto 0);	--For each 7-seg display LED
		--Enable_7seg : inout std_logic_vector(3 downto 0)	--Shift Register to enable 7-Seg Displays
		pin17, pin18_cs : in std_logic;
		pin1, pin2, pin3_sn, pin4_mosi	: out std_logic; 
		pin5, pin6, pin7_done, pin8_pgmn : out std_logic; 
		pin9_jtgnb, pin10_sda, pin11_scl : out std_logic; 
		pin16,  pin19_sclk, pin20_miso : out std_logic;
		pin21, pin22 : out std_logic
      );
end LFSRDiceRoller;

architecture LFSRDiceRoller_behavioral of LFSRDiceRoller is	

--Signals

signal sysClk : std_logic;
signal Roll_Button, Select_Button : std_logic;				--User input buttons
signal Display_7seg_LED : std_logic_vector (6 downto 0);	--For each 7-seg display LED
signal Enable_7seg : std_logic_vector(3 downto 0);			--Shift Register to enable 7-Seg Displays

--LFSR clock pre-scaler
--120khz Clock
signal LFSR_clk_prescaler : std_logic_vector (5 downto 0) := "110010";
signal LFSR_clk_prescaler_counter : std_logic_vector (5 downto 0) := (others => '0');
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

--For Oscillator clock
COMPONENT OSCH is
	-- synthesis translate_off      
	GENERIC  (NOM_FREQ: string := "12.09");
	-- synthesis translate_on      
		PORT (STDBY : IN std_logic;
		      OSC : OUT std_logic);
END COMPONENT OSCH;     
attribute NOM_FREQ : string;    
attribute NOM_FREQ of OSCinst0 : label is "12.09";

begin	   
	
---------------------------------------------------------------------------------------------
--Oscillator clock	
OSCInst0: OSCH
	--synthesis translate_off      
	GENERIC MAP( NOM_FREQ  => "12.09" )
	--synthesis translate_on      
		PORT MAP (STDBY=>'0',
			  OSC=>sysClk);
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
Display: process (sysClk)
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
Enable_7seg(3 downto 0) <= Enable_7seg_select(3 downto 0);
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
--Used to select through dice (d4, d6, d8, d10, d12, d20, d100)
--Takes pulse from Select dice button and changes selected dice
--Interacts with 7-seg display to output selected dice
--Interacts with Filter for Valid Numbers to change parameters
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
	dice_filter_output(2 downto 0) <= ('0' & LFSR_output_in(7) & LFSR_output_in(4)) + 1;     

--Valid d6 numbers
elsif (Selected_dice_output_in = "001") then
--fills unwanted bits with 0s    
dice_filter_output(7 downto 3) <= (others =>'0'); 
	--Checks if first 3 bits of LFSR output is between 1 and 6
	if (LFSR_output_in(4 downto 2) = 7 or LFSR_output_in(4 downto 2) = 0) then
    		dice_filter_output <= dice_filter_output;
    	else 
		--Saves LFSR number to filter (Only first 3 bits are important)
    		dice_filter_output(2 downto 0) <= LFSR_output_in(4 downto 2); 	
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
--fills unwanted bits with 0s
dice_filter_output(7 downto 4) <= (others =>'0');
	--Ignores case of '0' output
	   if LFSR_output_in(5 downto 2)=0 then
		dice_filter_output <= dice_filter_output;
	elsif LFSR_output_in(5 downto 2)<=10 then	    
		--Saves LFSR number to filter (Only first 4 bits are important)
    		dice_filter_output(3 downto 0) <= LFSR_output_in(5 downto 2);
    	elsif LFSR_output_in(5 downto 2)>=11 then
       		--Case is new number is greater than 11, fills 3-7
        	   if LFSR_output_in(0)='1' then
	    	--Takes input that is greater than 11, lops off 4th bit and replaces with 0
	       		dice_filter_output(3 downto 0) <= ('0' & LFSR_output_in(4 downto 2));
	    	--case is new number is greater than 11, fills 1-2 & 8-10
        	elsif LFSR_output_in(0)='0' then
			   if LFSR_output_in(5 downto 2)=11 then 	 --if case 11
						dice_filter_output(3 downto 0) <= LFSR_output_in(5 downto 2)-10; --sends 1
		  	elsif LFSR_output_in(5 downto 2)=12 then	 --if case 12
	    	    		dice_filter_output(3 downto 0) <= LFSR_output_in(5 downto 2)-10; --sends 2
		  	elsif LFSR_output_in(5 downto 2)=13 then	 --if case 13
	    	    		dice_filter_output(3 downto 0) <= LFSR_output_in(5 downto 2)-5; --sends 8
		  	elsif LFSR_output_in(5 downto 2)=14 then	 --if case 14
	    	    		dice_filter_output(3 downto 0) <= LFSR_output_in(5 downto 2)-5; --sends 9
		 	elsif LFSR_output_in(5 downto 2)=15 then	 --if case 15
	    	    		dice_filter_output(3 downto 0) <= LFSR_output_in(5 downto 2)-5; --sends 10
		  	end if;
		end if; 
 	end if;
		
--Valid d12 numbers
elsif (Selected_dice_output_in = "100") then
--fills unwanted bits with 0s
dice_filter_output(7 downto 4) <= (others =>'0');
	--Ignores case of 0, 13, 14 & 15 output
	   if (LFSR_output_in(6 downto 3)=0 or LFSR_output_in(6 downto 3)>=13) then
		dice_filter_output <= dice_filter_output;
	elsif (LFSR_output_in(6 downto 3)<=12) then
		--Saves LFSR number to filter (Only first 4 bits are important)
    		dice_filter_output(3 downto 0) <= LFSR_output_in(6 downto 3);  
	end if;
	
--Valid d20 numbers
elsif (Selected_dice_output_in = "101") then
--fills unwanted bits with 0s
dice_filter_output(7 downto 5) <= (others =>'0');
	--Ignores case of '0' or '31' output
	   if (LFSR_output_in(6 downto 2)=31) or (LFSR_output_in(6 downto 2)=0)  then
		dice_filter_output <= dice_filter_output;
	elsif (LFSR_output_in(6 downto 2)<=20) then
		--Saves LFSR number to filter (Only first 4 bits are important)
    		dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2); 
	elsif (LFSR_output_in(6 downto 2)>=21) then
        if LFSR_output_in(7)='1' then
			   if LFSR_output_in(6 downto 2)=21 then 	 --if case 21
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 1
			elsif LFSR_output_in(6 downto 2)=22 then 	 --if case 22
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 2
			elsif LFSR_output_in(6 downto 2)=23 then 	 --if case 23
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 3
			elsif LFSR_output_in(6 downto 2)=24 then 	 --if case 24
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 4
			elsif LFSR_output_in(6 downto 2)=25 then 	 --if case 25
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 5
			elsif LFSR_output_in(6 downto 2)=26 then 	 --if case 26
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 6
			elsif LFSR_output_in(6 downto 2)=27 then 	 --if case 27
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 7
			elsif LFSR_output_in(6 downto 2)=28 then 	 --if case 28
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 8
			elsif LFSR_output_in(6 downto 2)=29 then 	 --if case 29
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 9
			elsif LFSR_output_in(6 downto 2)=30 then 	 --if case 30
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-20; --sends 10
			end if;
        elsif LFSR_output_in(7)='0' then
			   if LFSR_output_in(6 downto 2)=21 then 	 --if case 21
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 11
			elsif LFSR_output_in(6 downto 2)=22 then 	 --if case 22
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 12
			elsif LFSR_output_in(6 downto 2)=23 then 	 --if case 23
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 13
			elsif LFSR_output_in(6 downto 2)=24 then 	 --if case 24
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 14
			elsif LFSR_output_in(6 downto 2)=25 then 	 --if case 25
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 15
			elsif LFSR_output_in(6 downto 2)=26 then 	 --if case 26
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 16
			elsif LFSR_output_in(6 downto 2)=27 then 	 --if case 27
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 17
			elsif LFSR_output_in(6 downto 2)=28 then 	 --if case 28
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 18
			elsif LFSR_output_in(6 downto 2)=29 then 	 --if case 29
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 19
			elsif LFSR_output_in(6 downto 2)=30 then 	 --if case 30
	       			dice_filter_output(4 downto 0) <= LFSR_output_in(6 downto 2)-10; --sends 20
			end if;
		end if;
    end if;
    
--Valid d100 numbers
elsif (Selected_dice_output_in = "110") then
--fills unwanted bits with 0s
dice_filter_output(7) <= '0';
	--Checks if first 7 bits of LFSR output is between 1 and 100
	if (LFSR_output_in(6 downto 0)>=101 or LFSR_output_in(6 downto 0)=0) then
    		dice_filter_output <= dice_filter_output;
    	else 
		--Saves LFSR number to filter (Only first 7 bits are important)
    		dice_filter_output(6 downto 0) <= LFSR_output_in(6 downto 0);     
 	end if;
end if;
end if;
end process;
--assigns filtered number to output pool
dice_number_pool <= std_logic_vector(dice_filter_output);

---------------------------------------------------------------------------------------------
--Random Number Pool
--Stores strings of bits based on what is currently inside the Filter of Valid Numbers
NumberPool: process(LFSR_clk, Roll_button_debounced, Selected_dice_output, dice_number_pool)
begin
Selected_dice_output_pool <= Selected_dice_output;
if (LFSR_clk = '1' and LFSR_clk'event) then
	if (roll_button_debounced = '1') then
		case Selected_dice_output_pool is
			when "000" => Number_pool_output <= dice_number_pool;
			when "001" => Number_pool_output <= dice_number_pool;
			when "010" => Number_pool_output <= dice_number_pool;
			when "011" => Number_pool_output <= dice_number_pool;
			when "100" => Number_pool_output <= dice_number_pool;
			when "101" => Number_pool_output <= dice_number_pool;
			when "110" => Number_pool_output <= dice_number_pool;
			when "111" => Number_pool_output <= "00000000";
		end case;
	end if;
end if;
end process;

Number_pool <= Number_pool_output;
---------------------------------------------------------------------------------------------
--Binary to BCD Converter
--Convers Binary output of Number Pool to BCD to be used by 7-seg Displays       	       
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
--Used to display currently selected dice
segDisp: process (Enable_7seg, selected_dice_output, BCD_ones, BCD_tens)
begin
if (Enable_7seg = "0111") then 						--Displays 10s place for Selected dice
	case Selected_dice_output is 
		when "000" => Display_7seg_LED <= "1111111";	--d4	--Displays Blank
		when "001" => Display_7seg_LED <= "1111111";	--d6	--Displays Blank
		when "010" => Display_7seg_LED <= "1111111";	--d8	--Displays Blank
		when "011" => Display_7seg_LED <= "1111001";	--d10	--Displays 1
		when "100" => Display_7seg_LED <= "1111001";	--d12	--Displays 1
		when "101" => Display_7seg_LED <= "0100100";	--d20	--Displays 2
		when "110" => Display_7seg_LED <= "1000000";	--d1(00)--Displays 0
		when "111" => Display_7seg_LED <= "1111111";	--Blank (Not used)
	end case;
	       
elsif (Enable_7seg = "1011") then 						--Displays 1s place for Selected Dice
	case Selected_dice_output is 
		when "000" => Display_7seg_LED <= "0001011";	--d4	--Displays 4
		when "001" => Display_7seg_LED <= "0000100";	--d6	--Displays 6
		when "010" => Display_7seg_LED <= "0000000";	--d8	--Displays 8
		when "011" => Display_7seg_LED <= "1000000";	--d10	--Displays 0
		when "100" => Display_7seg_LED <= "0110000";	--d12	--Displays 2
		when "101" => Display_7seg_LED <= "1000000";	--d20	--Displays 0
		when "110" => Display_7seg_LED <= "1000000";	--d1(00)--Displays 0
		when "111" => Display_7seg_LED <= "1111111";	--Blank (Not used)
	end case;

---------------------------------------------------------------------------------------------
--7-Seg Display logic (Rolled Dice)
--Used to display Rolled dice result
elsif (Enable_7seg = "1101") then 					--Displays 10s place for Rolled Dice
	case BCD_tens is
		when "0000" => Display_7seg_LED <= "1000000";	--Displays 0
		when "0001" => Display_7seg_LED <= "1111001";	--Displays 1
		when "0010" => Display_7seg_LED <= "0100100";	--Displays 2 
		when "0011" => Display_7seg_LED <= "0110000";	--Displays 3 
		when "0100" => Display_7seg_LED <= "0011001";	--Displays 4 
		when "0101" => Display_7seg_LED <= "0010010";	--Displays 5 
		when "0110" => Display_7seg_LED <= "0000010";	--Displays 6 
		when "0111" => Display_7seg_LED <= "1111000";	--Displays 7 
		when "1000" => Display_7seg_LED <= "0000000";	--Displays 8     
		when "1001" => Display_7seg_LED <= "0010000";	--Displays 9
	end case;

elsif (Enable_7seg = "1110") then 					--Displays 1s place for Rolled Dice
	case BCD_ones is
		when "0000" => Display_7seg_LED <= "1000000";	--Displays 0
		when "0001" => Display_7seg_LED <= "1011011";	--Displays 1
		when "0010" => Display_7seg_LED <= "0110000";	--Displays 2 
		when "0011" => Display_7seg_LED <= "0010010";	--Displays 3 
		when "0100" => Display_7seg_LED <= "0001011";	--Displays 4 
		when "0101" => Display_7seg_LED <= "0000110";	--Displays 5 
		when "0110" => Display_7seg_LED <= "0000100";	--Displays 6 
		when "0111" => Display_7seg_LED <= "1011010";	--Displays 7 
		when "1000" => Display_7seg_LED <= "0000000";	--Displays 8     
		when "1001" => Display_7seg_LED <= "0000010";	--Displays 9
	end case;
end if;
end process;

Select_Button <= pin17;
Roll_Button <= pin18_cs;

pin1 		<= Display_7seg_LED(6);
pin2 		<= Display_7seg_LED(5);
pin3_sn 	<= Display_7seg_LED(4);
pin4_mosi 	<= Display_7seg_LED(3);
pin5 		<= Display_7seg_LED(2);
pin8_pgmn 	<= Display_7seg_LED(1);
pin9_jtgnb 	<= Display_7seg_LED(0);

pin19_sclk 	<= Enable_7seg(0);
pin20_miso 	<= Enable_7seg(1);
pin21 		<= Enable_7seg(2);
pin22 		<= Enable_7seg(3);

pin6 		<= '0';
pin7_done 	<= '0'; 
pin10_sda 	<= '0';
pin11_scl 	<= '0';
pin16 		<= '0';
---------------------------------------------------------------------------------------------
end LFSRDiceRoller_behavioral;
