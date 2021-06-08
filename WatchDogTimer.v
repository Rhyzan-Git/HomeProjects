//////////////////////////////////////////////////////////////////////////////////
// Company: Teledyne Flir
// Engineer: Alex Williams
// 
// Create Date: 06/07/2021 10:50:10 AM
// Design Name: Watchdog Timer
// Module Name: WatchDogTimer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Observes changes in input, if delay between state changes is too long
// Watchdog timer triggers sending out a high output signal to another device.
// Dependencies: 
// 
// Revision: 1
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
`timescale 100us / 1us
module WatchDogTimer
  (
    input clk_1khz,  //1khz clock running inside the system
    input wd_in,     //Input signal from motor
    output wd_out     //Output signal to trigger shutdown
    );
  
//Constants
//uses 1khz signal as a counter
//hitting this limit triggers the shutdown signal (wd_out)
parameter c_shtdwn = 127; 

//Counters
reg [6:0] r_shtdwn_cnt = 0;
  
//Wires/regs  
wire edge_detect;        //Edge detector of watchdog in
reg wd_shtdwn = 1'b0;    //Shutdown signal to be assigned to output
reg wd_in_Q0 = 1'b0;     //Q side of wd_in register
reg wd_in_Q1 = 1'b0;
begin
 
//Edge detector, lasts 2 clock cycles
  always @ (posedge clk_1khz) begin
        wd_in_Q0 <= wd_in;
        wd_in_Q1 <= wd_in_Q0;
  end     
//assigns edge detect to wd_in xor (^) wd_in_q     
assign  edge_detect = wd_in_Q1 ^ wd_in_Q0;   

//Shutdown timer
  always @ (negedge clk_1khz)
  begin
    //Resets counter back to 0 and sets watchdog output signal to low on detected input
    if (edge_detect == 1) begin
        wd_shtdwn <= "0";
        r_shtdwn_cnt <= 0;
    end
        //Triggers shutdown ~128ms after last detected motor signal
    else if (r_shtdwn_cnt == c_shtdwn-1) // -1, since counter starts at 0   
                wd_shtdwn <= "1"; 
    else //Add to counter
                r_shtdwn_cnt <= r_shtdwn_cnt + 1;   
  end   
assign wd_out = wd_shtdwn;   

end 

/*
//Testbench code for WatchDogTimer
//////////////////////////////////////////////////////////////////////////////////
// Company: Teledyne Flir
// Engineer: Alex Williams
// 
// Create Date: 06/07/2021 01:11:48 PM
// Design Name: WatchDogTimer Testbench
// Module Name: WatchDogTimer_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench code for Watchdog timer 
// 
// Dependencies: 
// 
// Revision: 1
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 100us / 10us

module WatchDogTimer_tb ();
    reg r_clk_1khz = 1'b0 ;  //1khz clock running inside the system
    reg r_wd_in = 1'b0 ;     //Input signal from motor
    wire r_wd_out;     //Output signal to trigger shutdown
    //wire edge_det;
    
  WatchDogTimer UUT (
        .clk_1khz(r_clk_1khz),
        .wd_in(r_wd_in),
        .wd_out(r_wd_out));
        
initial
forever #5 r_clk_1khz <= ~r_clk_1khz;

  always begin
      #50 r_wd_in <= ~r_wd_in;
  end

endmodule
*/
