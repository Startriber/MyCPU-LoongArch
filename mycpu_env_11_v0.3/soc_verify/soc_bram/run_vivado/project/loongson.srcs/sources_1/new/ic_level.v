`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/20 16:03:25
// Design Name: 
// Module Name: ic_level
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


module ic_level(
input wire         clk,
input wire         reset,
input wire         wen,

input wire [31:0] pc,
input wire prediction,

output wire [31:0] ic_pc,
output wire ic_prediction
    );
    
reg  [31:0] ic_pc_r;
reg pre_r;

always@(posedge clk)
begin
    if(reset) begin
        ic_pc_r <= 32'h0;
        pre_r <= 1'b0;
        end
    else if(wen) begin
        ic_pc_r <= pc;
        pre_r <= prediction;
        end
    else begin
        ic_pc_r <= ic_pc_r;
        pre_r <= pre_r;
        end
        
end        

assign ic_pc = ic_pc_r;
assign ic_prediction = pre_r;
endmodule
