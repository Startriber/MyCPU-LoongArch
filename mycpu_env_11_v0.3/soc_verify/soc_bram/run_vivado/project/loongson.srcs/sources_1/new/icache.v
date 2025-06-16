`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/16 18:43:53
// Design Name: 
// Module Name: icache
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


module icache(
input wire reset,
input wire br_clr,
input wire clk,
input wire ena,
input wire [31:0] pc,
output wire [31:0] rdata,
output wire miss_stall,

output wire       inst_sram_en,
output wire[ 3:0] inst_sram_we,
output wire[31:0] inst_sram_addr,
output wire[31:0] inst_sram_wdata,
input  wire[31:0] inst_sram_rdata 
    );

reg valid;
always @(posedge clk) valid <= ~reset;


wire [19:0] tag;
wire [7:0] addr;
wire [1:0] inside_addr;
reg[31:0] pc_r;
wire miss;

always@(posedge clk)
begin
    if(reset)
        pc_r <= 32'h1c000000; 
    else
        pc_r <= pc;     
end

assign inside_addr = pc_r[3:2];
assign addr = pc[11:4];
assign tag = pc_r[31:12];
   
wire [31:0] rdata0_0,rdata0_1,rdata0_2,rdata0_3,
rdata1_0,rdata1_1,rdata1_2,rdata1_3;
wire [20:0] rtagv_0,rtagv_1;
 

wire [31:0] wdata0_0,wdata0_1,wdata0_2,wdata0_3,
wdata1_0,wdata1_1,wdata1_2,wdata1_3;
wire [20:0] wtagv_0,wtagv_1;
wire [3:0] wea_way1,wea_way0;
   
//read data    
 inst_way0_bank0 u_inst_way0_bank0(
 .addra(addr),
 .clka(clk),
 .dina(wdata0_0),
 .douta(rdata0_0),
 .ena(ena),
 .wea(wea_way0)
 ); 
 
 inst_way0_bank1 u_inst_way0_bank1(
 .addra(addr),
 .clka(clk),
 .dina(wdata0_1),
 .douta(rdata0_1),
 .ena(ena),
 .wea(wea_way0)
 ); 
 
 inst_way0_bank2 u_inst_way0_bank2(
 .addra(addr),
 .clka(clk),
 .dina(wdata0_2),
 .douta(rdata0_2),
 .ena(ena),
 .wea(wea_way0)
 );
 
 inst_way0_bank3 u_inst_way0_bank3(
 .addra(addr),
 .clka(clk),
 .dina(wdata0_3),
 .douta(rdata0_3),
 .ena(ena),
 .wea(wea_way0)
 );
 
 inst_way1_bank0 u_inst_way1_bank0(
 .addra(addr),
 .clka(clk),
 .dina(wdata1_0),
 .douta(rdata1_0),
 .ena(ena),
 .wea(wea_way1)
 );
 
 inst_way1_bank1 u_inst_way1_bank1(
 .addra(addr),
 .clka(clk),
 .dina(wdata1_1),
 .douta(rdata1_1),
 .ena(ena),
 .wea(wea_way1)
 );
 
 inst_way1_bank2 u_inst_way1_bank2(
 .addra(addr),
 .clka(clk),
 .dina(wdata1_2),
 .douta(rdata1_2),
 .ena(ena),
 .wea(wea_way1)
 );
 
 inst_way1_bank3 u_inst_way1_bank3(
 .addra(addr),
 .clka(clk),
 .dina(wdata1_3),
 .douta(rdata1_3),
 .ena(ena),
 .wea(wea_way1)
 );
 
 //read tagv
 inst_TAGV_0 tagv0(
 .addra(addr),
 .clka(clk),
 .dina(wtagv_0),
 .douta(rtagv_0),
 .ena(ena),
 .wea(wea_way0[0])
 );
 
 inst_TAGV_1 tagv1(
 .addra(addr),
 .clka(clk),
 .dina(wtagv_1),
 .douta(rtagv_1),
 .ena(ena),
 .wea(wea_way1[0])
 );

//choose
wire inside_addr_eq_0,inside_addr_eq_1,inside_addr_eq_2,inside_addr_eq_3;
wire choose_way0,choose_way1;

assign inside_addr_eq_0 = ~inside_addr[1] && ~inside_addr[0];
assign inside_addr_eq_1 = ~inside_addr[1] &&  inside_addr[0];
assign inside_addr_eq_2 =  inside_addr[1] && ~inside_addr[0];
assign inside_addr_eq_3 =  inside_addr[1] &&  inside_addr[0];

wire [19:0] rtag0,rtag1;

assign rtag0 = rtagv_0[20:1];
assign rtag1 = rtagv_1[20:1];

assign choose_way0 = ~(|(tag ^ rtag0));
assign choose_way1 = ~(|(tag ^ rtag1));

wire [31:0] way0_value,way1_value;

assign way0_value = inside_addr_eq_0 ? rdata0_0 : 
                    inside_addr_eq_1 ? rdata0_1 : 
                    inside_addr_eq_2 ? rdata0_2 : 
                                       rdata0_3 ;

assign way1_value = inside_addr_eq_0 ? rdata1_0 : 
                    inside_addr_eq_1 ? rdata1_1 : 
                    inside_addr_eq_2 ? rdata1_2 : 
                                       rdata1_3 ;

assign rdata = choose_way0 ? way0_value : 
                             way1_value ;

//miss 

reg [4:0] state;

assign miss = ~((choose_way0 & rtagv_0[0]) || (choose_way1 & rtagv_1[0])) && valid && ~br_clr;
assign miss_stall = miss;


//read mem
reg [3:0] wea_r;

reg [127:0] all_rdata_r;
wire [31:0] rdata_0,rdata_1,rdata_2,rdata_3;


assign inst_sram_en = |(state[3:0]);
assign inst_sram_we = 4'h0;
assign inst_sram_wdata = 32'h0;
assign inst_sram_addr = {pc[31:4],state[2]|state[3],state[1]|state[3],2'b0};
          

always@(posedge clk)
begin
    if(reset) begin
        state <= 5'h0;
    end
    else if(~(|(state | wea_r)) || br_clr) begin
        state <= {4'b0,miss};
    end
    else begin
        state <= {state,1'b0};
    end
end

always@(posedge clk)
begin
    if(reset) begin
        wea_r <= 4'h0;
    end
    else begin
        wea_r <= {4{state[4]}};
    end
end


always@(posedge clk)
begin
    if(reset)
        all_rdata_r <= 128'h0;
    else if(state[1])
        all_rdata_r[31:0] <= inst_sram_rdata;
    else if(state[2])
        all_rdata_r[63:32] <= inst_sram_rdata;
    else if(state[3])
        all_rdata_r[95:64] <= inst_sram_rdata;    
    else if(state[4])
        all_rdata_r[127:96] <= inst_sram_rdata;
    else
        all_rdata_r <= 128'h0;
end

//wr
reg replace;

always@(posedge clk)
begin
    if(reset)
        replace <= 1'b0;
    else
        replace <= ~replace;    
end

assign {wdata0_3,wdata0_2,wdata0_1,wdata0_0} = all_rdata_r;
assign {wdata1_3,wdata1_2,wdata1_1,wdata1_0} = all_rdata_r;

assign wtagv_0 = {tag,1'b1};
assign wtagv_1 = {tag,1'b1};

assign wea_way0 = wea_r & {4{~replace}};
assign wea_way1 = wea_r & {4{replace}};

endmodule
