/*
Notes: 
//Written in Verilog
//Shutdown triggers 1/8th of a second after not seeing restart pulse
/working with 1khz clock
restart must trigger on rising edge of pulse
*/

module watchdogTimer
  (
    clk_1khz,  //assumes a 1khz clock running inside the system
    const_clk  //assumes a costant 12Mhz system clock
    );

input clk_1khz;   //1khz
inout const_clk; //12Mhz
output shutdown;
  
//Constants
parameter c_clk_8hz = 750000; // uses 12Mhz clock for shutdown signal

//Counters
reg [19:0] r_clk_8hz = 0;

//Signal toggles
reg t_clk_8hz = 1'b0;

begin
 
  //Generates 8hz timer, runs off os 12Mhz system clock
  always @ (posedge const_clk)
    begin

      //restart condition
      if (posedge ck_1khz)  
        begin        
          t_clk_8hz <= '0';
          r_clk_8hz <= 0;
        end

      //No restart detected
      else
        r_clk_8hz <= r_clk_8hz + 1;
    end

  //watchdog triggers
  if (r_clk_8hz == c_clk_8hz)
    begin
      shutdown <= '1';
    end
  
end module
