/* Notes: 
Written in Verilog
Shutdown triggers 1/8th of a second after not seeing restart pulse
working with 1khz clock
restart must trigger on rising edge of pulse
*/

module watchdogTimer
  (
    clk_1khz,  //1khz clock running inside the system
    wd_in,     //Input signal from motor
    wd_out     //Output signal to trigger shutdown
    );

input clk_1khz;
input wd_in;
output wd_out;
  
//Constants
//uses 1khz signal as a counter
//hitting this limit triggers the shutdown signal (wd_out)
parameter c_shtdwn = 63; 

//Counters
reg [5:0] r_shtdwn_cnt = 0;
  
//Wires  
wire edge_detect; //Edge detector of watchdog in
wire wd_in_Q;     //Q side of wd_in register
  
begin
 
//Edge detector
  always @ (posedge clk_1khz)
    begin  
      wd_in_Q <= wd_in     
    end
  edge_detect <= wd_in xor wd_in_Q;   

//Shutdown timer
  always @ (posedge clk_1khz)
    begin
      //Triggers shutdown ~126ms after last detected motor signal
      if (r_shtdwn_cnt == c_shtdwn-1) // -1, since counter starts at 0   
          wd_out <= '1';
      else if (edge_detect == '1') begin
          wd_out <= '0';
          r_shtdwn_cnt <= 0;
      end
      else
          r_shtdwn_cnt <= r_shtdwn_cnt + 1;
    end
  
end module
