module mycpu_top(
    input wire        clk,
    input wire        resetn,
    // inst sram interface
    output wire       inst_sram_en,
    output wire[ 3:0] inst_sram_we,
    output wire[31:0] inst_sram_addr,
    output wire[31:0] inst_sram_wdata,
    input  wire[31:0] inst_sram_rdata,
    // data sram interface
    output wire       data_sram_en,
    output wire[ 3:0] data_sram_we,
    output wire[31:0] data_sram_addr,
    output wire[31:0] data_sram_wdata,
    input  wire[31:0] data_sram_rdata,
    // trace debug interface
    output wire[31:0] debug_wb_pc,
    output wire[ 3:0] debug_wb_rf_we,
    output wire[ 4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn; 

wire         pcwr;
wire         IF_IDwr;
wire         ID_EXwr;
wire         EX_MEMwr;
wire         MEM_WBwr;
wire         IF_IDreset;
wire         ID_EXreset;
wire         EX_MEMreset;
wire         MEM_WBreset;
wire         ms_to_ws_valid;
wire         rf_valid;
wire [63: 0] fs_to_ds_bus;
wire [195:0] ds_to_es_bus;
wire [75: 0] es_to_ms_bus;
wire [106: 0] ms_to_ws_bus;
wire [37: 0] ms_to_ds_bus;
wire [37: 0] ws_to_rf_bus;
wire [32: 0] br_bus;

wire [4:0] es_to_ds_dest;
wire [31:0] es_to_ds_value;
wire es_load_op,ms_load_op;
wire es_gr_we;

wire mul_ce,mulu_ce;
wire ex_mul_ce,ex_mulu_ce;

reg [31:0] pc;

wire [31:0] seq_pc,br_pc;
wire [31:0] next_pc;

wire branch;
wire branch_cancel,load_stall,calculate_stall;

// pre_IF stage
assign pcwr = ~load_stall && ~calculate_stall;
assign IF_IDwr = ~load_stall && ~calculate_stall;
assign ID_EXwr = ~calculate_stall;
assign EX_MEMwr = 1;
assign MEM_WBwr = 1;

assign IF_IDreset = reset | branch_cancel;
assign ID_EXreset = reset | load_stall | branch_cancel;
assign EX_MEMreset = reset | calculate_stall;
assign MEM_WBreset = reset;

assign ex_mul_ce = ~ID_EXreset & mul_ce;
assign ex_mulu_ce = ~ID_EXreset & mulu_ce;

assign seq_pc = pc + 32'h4;
assign {
        branch       ,
        br_pc         } = br_bus;
assign branch_cancel = branch;

assign next_pc = ~pcwr ? pc : 
                 branch_cancel ? br_pc : 
                 seq_pc;


assign inst_sram_en    = ~reset;
assign inst_sram_we    = 4'h0;
assign inst_sram_addr  = next_pc;
assign inst_sram_wdata = 32'b0;


// IF stage
always@(posedge clk)
begin
    if(reset)
    begin
        pc <= 32'h1bfffffc;
    end
    else
    begin
        pc <= next_pc;
    end    
end
 
assign fs_to_ds_bus = {
                       inst_sram_rdata,
                       pc              };


// ID stage
assign rf_valid = ~reset;

id_level id_level(
    .clk            (clk            ),
    .reset          (IF_IDreset     ),
    //wr
    .wen            (IF_IDwr        ),
    //from fs
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    //to es
    .ds_to_es_bus   (ds_to_es_bus   ),
    .mul_ce         (mul_ce         ),
    .mulu_ce        (mulu_ce        ),
    //to rf: for write back
    .rf_valid       (rf_valid       ),
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    
	.es_to_ds_dest  (es_to_ds_dest  ),
	.es_to_ds_value (es_to_ds_value ),
	.es_load_op     (es_load_op     ),
	.es_gr_we       (es_gr_we       ),
	
	.ms_to_ds_bus   (ms_to_ds_bus   ),
	.ms_load_op     (ms_load_op     ),
	
	.load_stall     (load_stall     )
);
// EXE stage
ex_level ex_level(
    .clk            (clk            ),
    .reset          (ID_EXreset     ),
    //allowin
    .wen            (ID_EXwr        ),
    //from ds
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to ms
    .es_to_ms_bus   (es_to_ms_bus   ),
    .mul_ce         (ex_mul_ce      ),
    .mulu_ce        (ex_mulu_ce     ),
    // to br
    .br_bus         (br_bus         ),    
    // data sram interface
    .data_sram_en   (data_sram_en   ),
    .data_sram_wen  (data_sram_we  ),
    .data_sram_addr (data_sram_addr ),
    .data_sram_wdata(data_sram_wdata),
    
	.es_to_ds_dest  (es_to_ds_dest  ),
	.es_to_ds_value (es_to_ds_value ),
	.es_load_op     (es_load_op     ),
	.es_gr_we       (es_gr_we       ),
	
	.calculate_stall(calculate_stall)
);
// MEM stage
mem_level mem_level(
    .clk            (clk            ),
    .reset          (EX_MEMreset    ),
    //allowin
    .wen            (EX_MEMwr       ),
    //from es
    .es_to_ms_bus   (es_to_ms_bus   ),
    //to ws
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //from data-sram
    .data_sram_rdata(data_sram_rdata),
    .ms_to_ds_bus   (ms_to_ds_bus   ),
    .ms_load_op     (ms_load_op     )
);
// WB stage
wb_level wb_level(
    .clk            (clk            ),
    .reset          (MEM_WBreset          ),
    //allowin
    .wen            (MEM_WBwr             ),
    //from ms
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    //trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_we  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

endmodule