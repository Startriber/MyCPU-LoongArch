`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/08 16:28:23
// Design Name: 
// Module Name: wb_level
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


module wb_level(
    input wire                          clk           ,
    input wire                          reset         ,
    //allowin
    input wire                          wen           ,
    //from ms
    input wire [106:                 0]  ms_to_ws_bus  ,
    //to rf: for write back
    output wire[37                 :0]  ws_to_rf_bus  ,
    //trace debug interface
    output wire[31:0] debug_wb_pc     ,
    output wire[ 3:0] debug_wb_rf_wen ,
    output wire[ 4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
	
);


reg [106:0] ms_to_ws_bus_r;
wire        ws_gr_we;
wire [ 4:0] ws_dest;
wire [31:0] ws_final_result;
wire [31:0] ws_alu_result;
wire [31:0] ws_pc;
wire        ws_ld_b;
wire        ws_ld_h;
wire        ws_ld_bu;
wire        ws_ld_hu;
wire [31:0] ws_mem_result;
wire        ws_res_from_mem;       

assign {ws_mem_result  ,
        ws_ld_b     ,
        ws_ld_h     ,
		ws_ld_bu    ,
		ws_ld_hu    ,
        
        ws_res_from_mem,
        ws_gr_we       ,  //69:69
        ws_dest        ,  //68:64
        ws_alu_result,  //63:32
        ws_pc             //31:0
       } = ms_to_ws_bus_r;

wire        rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;

always @(posedge clk) begin
    if (reset) begin
        ms_to_ws_bus_r <= 107'h0;
    end
    else if (wen) begin
        ms_to_ws_bus_r <= ms_to_ws_bus;
    end
    else begin
        ms_to_ws_bus_r <= ms_to_ws_bus_r;
    end
end

assign rf_we    = ws_gr_we;
assign rf_waddr = ws_dest;
assign rf_wdata = ws_final_result;

assign ws_to_rf_bus = {rf_we,
                       rf_waddr,
                       rf_wdata};

wire [31:0] mem;

assign mem = ws_mem_result >> {ws_alu_result[1:0],3'b0};

assign ws_final_result = (ws_ld_b|ws_ld_bu)? {{24{mem[7]&ws_ld_b}},mem[7:0]} :                   
						 (ws_ld_h|ws_ld_hu)? {{16{mem[15]&ws_ld_h}},mem[15:0]} : 
                          ws_res_from_mem  ?   ws_mem_result :
                                               ws_alu_result;


// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_wen   = {4{rf_we}};
assign debug_wb_rf_wnum  = ws_dest;
assign debug_wb_rf_wdata = ws_final_result;


endmodule
