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

input wire [137:0] ic_to_cs_bus,

output wire [63:0] cs_to_ds_bus,

output wire        miss
    );
    
reg [137:0] ic_to_cs_bus_r;
wire [31:0] rdata0,rdata1;
wire [20:0] rtagv0,rtagv1,tag;

wire [31:0] cs_pc;

assign tag = cs_pc[31:12];
assign {rdata0,
        rdata1,
        rtagv0,
        rtagv1,
        cs_pc} = ic_to_cs_bus_r;

always@(posedge clk)
begin
    if(reset)
        ic_to_cs_bus_r <= 138'h0;
    else if(wen)
        ic_to_cs_bus_r <= ic_to_cs_bus;
    else
        ic_to_cs_bus_r <= ic_to_cs_bus_r;
end        

wire choose_way0,choose_way1;

assign choose_way0 = ~(|(rtagv0[20:1] ^ tag)) && rtagv0[0];
assign choose_way1 = ~(|(rtagv1[20:1] ^ tag)) && rtagv1[0];

assign miss = ~choose_way0 & ~choose_way1;

wire [31:0] inst; 

assign inst = choose_way0 ? rdata0 : rdata1;

assign ic_to_cs_bus = {inst,cs_pc};
endmodule
