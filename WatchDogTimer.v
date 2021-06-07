//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2021 10:50:10 AM
// Design Name: 
// Module Name: WatchDogTimer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
/* Notes: 
Written in Verilog
Shutdown triggers 1/8th of a second after not seeing restart pulse
working with 1khz clock
restart must trigger on rising edge of pulse
*/

module WatchDogTimer
  (
    input clk_1khz,  //1khz clock running inside the system
    input wd_in,     //Input signal from motor
    output wd_out     //Output signal to trigger shutdown
    );
  
//Constants
//uses 1khz signal as a counter
//hitting this limit triggers the shutdown signal (wd_out)
parameter c_shtdwn = 63; 

//Counters
reg [5:0] r_shtdwn_cnt = 0;
  
//Wires  
wire edge_detect; //Edge detector of watchdog in
reg wd_shtdwn;    //Shutdown signal to be assigned to output
reg wd_in_Q;      //Q side of wd_in register

begin
 
//Edge detector
  always @ (posedge clk_1khz) begin
        wd_in_Q <= wd_in;
  end     
//assigns edge detect to wd_in xor (^) wd_in_q     
assign  edge_detect = wd_in ^ wd_in_Q;   

//Shutdown timer
  always @ (posedge clk_1khz)
  begin
      //Triggers shutdown ~126ms after last detected motor signal
      if (r_shtdwn_cnt == c_shtdwn-1) // -1, since counter starts at 0   
            wd_shtdwn <= "1"; 
      else begin   
          if (edge_detect == "1") begin
                wd_shtdwn <= "0";
                r_shtdwn_cnt <= 0;
          end else
          r_shtdwn_cnt <= r_shtdwn_cnt + 1;      
      end   
   end   
assign wd_out = wd_shtdwn;   

end 
endmodule
