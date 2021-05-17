--Sections for project
--Internal PseudoRandom Number Generator
--	Fast Clock to cycle through list of random numbers
--	Should each dice have a PseduoRNG or is it possible to have one central PsuedoRNG?
--		Each number is divisable by 600 in some form. Could each switch enable a divider resulting in the correct dice being selected?
--			d4 - Divides by 150
--			d6 - Divides by 100
--			d8 - Divides by 75
--			d10 - Divides by 60
--			d12 - Divides by 50
--			d20 - Divides by 30
--			d100 - Divides by 6
--	Look up LFSR, might be easier to impliment one for each dice Possible help - http://outputlogic.com/?page_id=275
--User interface 
--	x2 7-Seg Displays 
--		Must display result of roll and hold until cleared
--	Selector switches for 1d4, 1d6, 1d8, 1d10, 1d20, 1d100
--		Will display on 7-Seg which is selected at the moment the switch is enabled
-- 		See PsuedoRNG section, ideally one generator for the whole system
--	Roll button
--		Rolls currently selected dice and sends result to 7-segs to be displayed
--		Holds result until cleared
--	Clear roll button
--		Clears Flip-Flop data
--Switch Debounce


entity D20_Roller is
    Port(
Roll_button : in std:logic;
AN_7seg : inout std_logic_vector(3 downto 0);
Display_7seg_LED : out std_logic_vector(6 downto 0);
Reset : inout std_ logic;
);

Signal Roll_button_debounced, Debounce_1, Debounce_2, Debounce_3 : std_logic;
Signal Pause : std_logic;
Signal Dice_side : std_logic_vector(19 downto 0);
Signal Roll : std_logic_vector(19 downto 0);
Signal Dice_1s : std_logic_vector(1 downto 0);
Signal Dice_10s : std_logic_vector(3 downto 0);


--Prescaler determines the clock frequency. (System Clock/Desired clock)/2 = Prescaler. --Convert to binary afterwards.
--For 100hz Clock
Signal Debounce_clk_prescaler : std_logic_vector (15 downto 0) := “1110101001100000”;
Signal Debounce_clk_prescaler_counter : std_logic_vector (15 downto 0) := (others => ‘0’);
Signal Debounce_clk : std_logic := ‘0’;

--For 400hz Clock
Signal Display_clk_prescaler : std_logic_vector (13 downto 0) := “11101010011000”;
Signal Dispaly_clk_prescaler_counter : std_logic_vector (13 downto 0) := (others => ‘0’);
Signal Display_clk : std_logic := ‘0’;

- For 7.7khz Clock
Signal Roller_clk_prescaler : std_logic_vector (9 downto 0) := “1100001011”;
Signal Roller_clk_prescaler_counter : std_logic_vector (9 downto 0) := (others => ‘0’);
Signal Roller_clk : std_logic := ‘0’;

--Clock generators
--Generates a 100hz clock based on the 12Mhz system clock
If rising_edge(sysClk) then
	Debounce_clk_prescaler_counter <= Debounce_clk_prescaler_counter + 1;
	If (Debounce_clk_prescaler_counter > Debounce_clk_prescaler) then 
		Debounce_clk <= not Debounce_clk;
	  	Debounce_clk_prescaler_counter <= (others => ‘0’);
End if;
End if;

--Generates a 400hz clock based on the 12Mhz system clock
If rising_edge(sysClk) then
	Display_clk_prescaler_counter <= Display_clk_prescaler_counter + 1;
	If (Display_clk_prescaler_counter > Display_clk_prescaler) then 
		Display_clk <= not Display_clk;
	  	Display_clk_prescaler_counter <= (others => ‘0’);
End if;
End if;

--Pauses Roller clock if roll button is pressed
If (Pause = "1") then
Roller_clk <= "0";
--Generates a 7.7Khz clock based on the 12Mhz system clock
Elsif rising_edge(sysClk) then
	Roller_clk_prescaler_counter <= Roller_clk_prescaler_counter + 1;
	If (Roller_clk_prescaler_counter > Roller_clk_prescaler) then 
		Roller_clk <= not Roller_clk;
	  	Roller_clk_prescaler_counter <= (others => ‘0’);
End if;
End if;

--User input
--Shift register to debounce button press
If rising_edge(Debounce_clk) then
	Debounce_1 <= Roll_button; 
Debounce_2 <= Debounce_1; 
Debounce_3 <= Debounce_2;
End if;

--Single pulse sampling the first two blocks of the shift register. Once the third block goes high the pulse goes low.
Roll_button_debounced <= Debounce_1 and Debounce_2 and not Debounce_3;

--Starts pause condition if roll button is pressed
Pause <= Roll_button_debounced or (Pause and not Reset);

--Sets roll value after clock is paused
If (Pause = "1") then
Roll <= Dice_side;
End if;

--Back-end
--Enables the 7seg Displays
If (reset = ‘1’) then
	AN_7seg <= “0001”;
Elsif rising_edge(Display_clk) then
	AN_7seg(1) <= AN_7seg(0); AN_7seg(2) <= AN_7seg(1); 
AN_7seg(3) <= AN_7seg(2); AN_7seg(0) <= AN_7seg(3);
End if;

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
if (AN_7seg = "0001") then 						--Displays 1s place
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

 if (AN_7seg = "0010") then 					--Displays 10s place
    if Dice_10s = “00” then Display_7seg_LED <= "0111111";	--Displays 0
    elsif Dice_10s = “01” then Display_7seg_LED <= "0000110";	--Displays 1
    elsif Dice_10s = “10” then Display_7seg_LED <= "1011011"; 	--Displays 2
    end if;
end if;
	
end process;
end behavioral;
