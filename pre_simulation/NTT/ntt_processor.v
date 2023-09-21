`include "../NTT/addr_generator.v"
`include "../NTT/BU_processor.v"
`include "../NTT/twiddle_factor.v"
`include "../NTT/buf_96x32.v"

module ntt_processer (
    input clk,
    input rst,
    input start,
    input [1:0] mode, // 0:NTT, 1:INVNTT, 2:MULT, 3:ADDSUB
    input is_add_or_sub,
    input [7:0] ram_r_start_offset_A,
    input [7:0] ram_r_start_offset_B,
    input [7:0] ram_w_start_offset,
    input [95:0] ram_rdata,
    output reg last_cycle,
    output reg ram_wen,
    output [7:0] ram_raddr,
    output [7:0] ram_waddr,
    output reg [95:0] ram_wdata
);

parameter WAIT_COMMAND_AND_FRST_CYCLE = 2'd0;
parameter PROCESSING = 2'd1;
parameter LAST_CYCLE = 2'd2;

`define NTT 2'd0
`define INVNTT 2'd1
`define MULT 2'd2
`define ADDSUB 2'd3

reg [1:0] st, nst; // state register
reg [7:0] cycle_cnt, ncnt;
reg [2:0] stage;
reg in_buf_pre_load;
reg in_buf_load;
reg type;
reg [7:0] ram_r_start_offset;
reg buf_wen;
reg [95:0] BP_in_data;
reg [4:0] buf_raddr;

wire [6:0] coef_addr;
wire [4:0] ag_raddr_out, ag_waddr_out;
wire [23:0] coef_rom_out;
wire [95:0] buf_rdata, buf_wdata;
wire [95:0] BP_out_data;

reg [1:0] mode_reg;
reg is_add_or_sub_reg;
reg [7:0] ram_r_start_offset_A_reg;
reg [7:0] ram_r_start_offset_B_reg;
reg [7:0] ram_w_start_offset_reg;

addr_generator AG (
    .clk(clk),
    .rst(rst),
    .mode(start ? mode : mode_reg),
    .cycle_cnt(cycle_cnt),
    .stage(stage),
    .coef_addr(coef_addr),
    .raddr(ag_raddr_out),
    .waddr(ag_waddr_out)
);

BU_processor BP (
    .clk(clk),
    .rst(rst),
    .op_mode(start ? mode : mode_reg),  
    .stage(stage), 
    .in_buf_pre_load(in_buf_pre_load),
    .in_buf_load(in_buf_load),
    .type(type), 
    .in_data(BP_in_data),
    .in_coef(coef_rom_out),
    .out_data(BP_out_data)
);

twiddle_factor ROM (
    .clk(clk),
    .addr(coef_addr),
    .dout(coef_rom_out)
);

assign buf_wdata = BP_out_data; 
buf_96x32 ntt_buf (
    .clk(clk),
    .rst(rst),
    .wen(buf_wen),
    .raddr(buf_raddr),
    .waddr(ag_waddr_out),
    .din(buf_wdata),
    .dout(buf_rdata)
);

assign ram_raddr = ram_r_start_offset + ag_raddr_out;
assign ram_waddr = mode == `NTT || mode == `INVNTT ? ram_w_start_offset_reg + ag_waddr_out : ram_w_start_offset_reg + buf_raddr;

// control logic
always @(posedge clk or posedge rst) begin
    if(rst) begin
        st <= WAIT_COMMAND_AND_FRST_CYCLE;
        cycle_cnt <= 8'd0;
    end
    else begin
        st <= nst;
        cycle_cnt <= ncnt;
    end
end

always @(*) begin
    case (st)
        WAIT_COMMAND_AND_FRST_CYCLE : begin
            stage = 3'd0;
            if(start) begin
                nst = PROCESSING;
                ncnt = cycle_cnt + 1;
            end
            else begin
                nst = st;
                ncnt = 8'd0;
            end
        end 
        PROCESSING : begin
            ncnt = cycle_cnt + 1;
            case(mode_reg)
            `NTT, `INVNTT: begin
                nst = cycle_cnt == 8'd228 ? LAST_CYCLE : PROCESSING;
                stage = cycle_cnt[7:5];
            end
            `MULT: begin
                nst = cycle_cnt == 8'd138 ? LAST_CYCLE : PROCESSING;
                stage = { 1'b0, ~cycle_cnt[1], cycle_cnt[0] }; // 2(10) -> 0(00), 3(11) -> 1(01), 0(00) -> 2(20), 1(01) -> 3(11) 
            end
            `ADDSUB: begin
                nst = cycle_cnt == 8'd66 ? LAST_CYCLE : PROCESSING;
                stage = { 2'b0, cycle_cnt[0] };
            end
            endcase
        end 
        LAST_CYCLE : begin
            nst = WAIT_COMMAND_AND_FRST_CYCLE;
            ncnt = 8'd0;
            stage = 3'd0;
        end 
        default: begin
            nst = WAIT_COMMAND_AND_FRST_CYCLE;
            stage = 3'd0;
            ncnt = 8'd0;
        end
    endcase
end

always @(*) begin
    case (st)
        WAIT_COMMAND_AND_FRST_CYCLE : begin
            in_buf_pre_load = mode == `MULT || mode == `ADDSUB;
            in_buf_load = 1'b0;
            type = mode == `ADDSUB ? is_add_or_sub : 1'b0;
            ram_r_start_offset = ram_r_start_offset_A;
            last_cycle = 1'b0;
            ram_wen = 1'b0;
            buf_wen = 1'b0;
            BP_in_data = ram_rdata;
            ram_wdata = 0;
            buf_raddr = 0;
        end 
        PROCESSING : begin
            last_cycle = 1'b0;
            case(mode_reg)
            `NTT, `INVNTT: begin
                in_buf_pre_load = 1'b0;
                in_buf_load = 1'b0;
                type = cycle_cnt[0];
                ram_r_start_offset = ram_r_start_offset_A_reg;
                ram_wen = cycle_cnt > 8'd197;
                buf_wen = cycle_cnt > 8'd5 && cycle_cnt <= 8'd197;
                BP_in_data = stage == 3'd0 ? ram_rdata : buf_rdata;
                ram_wdata = BP_out_data;
                buf_raddr = ag_raddr_out;
            end
            `MULT: begin
                in_buf_pre_load = cycle_cnt[1:0] == 2'd0;
                in_buf_load = cycle_cnt[1:0] == 2'd1;
                type = 1'b0;
                ram_r_start_offset = cycle_cnt[0] ? ram_r_start_offset_B_reg : ram_r_start_offset_A_reg;
                ram_wen = cycle_cnt > 8'd107;
                buf_wen = cycle_cnt > 8'd12 && cycle_cnt[1:0] == 2'd3;
                BP_in_data = ram_rdata;
                ram_wdata = buf_rdata;
                buf_raddr = cycle_cnt - 8'd108;
            end
            `ADDSUB: begin
                in_buf_pre_load = ~cycle_cnt[0];
                in_buf_load = cycle_cnt[0];
                type = is_add_or_sub_reg;
                ram_r_start_offset = cycle_cnt[0] ? ram_r_start_offset_B_reg : ram_r_start_offset_A_reg;
                ram_wen = cycle_cnt > 8'd35;
                buf_wen = cycle_cnt > 8'd3 && cycle_cnt[0];
                BP_in_data = ram_rdata;
                ram_wdata = buf_rdata;
                buf_raddr = cycle_cnt - 8'd36;
            end
            endcase
        end 
        LAST_CYCLE : begin
            in_buf_pre_load = 1'b0;
            in_buf_load = 1'b0;
            type = 1'b0;
            ram_r_start_offset = ram_w_start_offset_reg;
            last_cycle = 1'b1;
            ram_wen = 1'b1;
            buf_wen = 1'b0;
            BP_in_data = ram_rdata;
            ram_wdata = BP_out_data;
            buf_raddr = 5'd31;
        end 
        default: begin
            in_buf_pre_load = 1'b0;
            in_buf_load = 1'b0;
            type = 1'b0;
            ram_r_start_offset = ram_r_start_offset_A;
            last_cycle = 1'b0;
            ram_wen = 1'b0;
            buf_wen = 1'b0;
            BP_in_data = ram_rdata;
            ram_wdata = 0;
            buf_raddr = 0;
        end
    endcase
end
// end of control logic

always @(posedge clk or posedge rst) begin
    if(rst) begin
        mode_reg <= 0;
        is_add_or_sub_reg <= 0;
        ram_r_start_offset_A_reg <= 0;
        ram_r_start_offset_B_reg <= 0;
        ram_w_start_offset_reg <= 0;
    end
    else begin
        if(start) begin
            mode_reg <= mode;
            is_add_or_sub_reg <= is_add_or_sub;
            ram_r_start_offset_A_reg <= ram_r_start_offset_A;
            ram_r_start_offset_B_reg <= ram_r_start_offset_B;
            ram_w_start_offset_reg <= ram_w_start_offset;
        end
    end
end

endmodule
