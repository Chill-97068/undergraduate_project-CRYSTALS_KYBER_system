module addr_generator (
    input clk,
    input rst,
    input [1:0] mode,
    input [7:0] cycle_cnt,
    input [2:0] stage,
    output reg [6:0] coef_addr,
    output reg [4:0] raddr,
    output reg [4:0] waddr
);

`define NTT 2'd0
`define INVNTT 2'd1
`define MULT 2'd2
`define ADDSUB 2'd3

reg [4:0] stage_offset;
reg [4:0] raddr_offset;
reg [6:0] coef_addr_offset;
reg [6:0] coef_addr_cnt;

wire [7:0] cycle_cnt_sub_2;
assign cycle_cnt_sub_2 = cycle_cnt - 2;

reg [4:0] waddr_shift_reg [5:0];

always @(*) begin
    case(mode)
    `NTT: begin
        case(stage)
        3'd0: stage_offset = 5'd16;
        3'd1: stage_offset = 5'd8;
        3'd2: stage_offset = 5'd4;
        3'd3: stage_offset = 5'd2;
        default: stage_offset = 5'd1;
        endcase
    end
    `INVNTT: begin
        case(stage)
        3'd5: stage_offset = 5'd16;
        3'd4: stage_offset = 5'd8;
        3'd3: stage_offset = 5'd4;
        3'd2: stage_offset = 5'd2;
        default: stage_offset = 5'd1;
        endcase
    end
    default: begin // MULT, ADDSUB
        stage_offset = 5'd0;
    end
    endcase
end


always @(*) begin
    case(mode)
    `NTT: begin
        coef_addr_offset = 7'd1 << stage;
        coef_addr_cnt = stage == 3'd6 ? {cycle_cnt[4:0], 1'b0} : (cycle_cnt[4:0] >> (3'd5-stage));
    end
    `INVNTT: begin
        coef_addr_offset = 7'd1 << (3'd7 - stage);
        coef_addr_cnt = stage == 3'd0 ? {cycle_cnt[4:0], 1'b0} + 6'd2 :
                        stage == 3'd1 || stage == 3'd6 ? (cycle_cnt[4:0] >> (stage-1)) + 6'd1 :
                        { (cycle_cnt[4:0] >> (stage)), 1'b0 } + (cycle_cnt[0] ? 6'd2 : 6'd1);
    end
    `MULT: begin
        coef_addr_offset = 7'd64;
        coef_addr_cnt = { cycle_cnt_sub_2[7:2], 1'b0 };
    end
    `ADDSUB: begin
        coef_addr_offset = 7'd0;
        coef_addr_cnt = 7'd0;
    end
    endcase
end

always @(*) begin
    case(mode)
    `NTT: begin
        case(stage)
        3'd0: raddr_offset = 5'd0;
        3'd1: raddr_offset = { 1'b0, cycle_cnt[4], 3'b0 } ; // +0(0~15), +8(16~31)
        3'd2: raddr_offset = { 1'b0, cycle_cnt[4:3], 2'b0 } ; // +0(0~7), +4(8~15), +8(16~23), +12(24~31)
        3'd3: raddr_offset = { 1'b0, cycle_cnt[4:2], 1'b0 } ; // +0(0~3), +2(4~7), +4(8~12) ......
        default: raddr_offset = { 1'd0, cycle_cnt[4:1] };
        endcase
    end
    `INVNTT: begin
        case(stage)
        3'd5: raddr_offset = 5'd0;
        3'd4: raddr_offset = { 1'b0, cycle_cnt[4], 3'b0 } ; // +0(0~15), +8(16~31)
        3'd3: raddr_offset = { 1'b0, cycle_cnt[4:3], 2'b0 } ; // +0(0~7), +4(8~15), +8(16~23), +12(24~31)
        3'd2: raddr_offset = { 1'b0, cycle_cnt[4:2], 1'b0 } ; // +0(0~3), +2(4~7), +4(8~12) ......
        default: raddr_offset = { 1'd0, cycle_cnt[4:1] };
        endcase        
    end
    `MULT: begin
        raddr_offset = cycle_cnt[7:2];
    end
    `ADDSUB: begin
        raddr_offset = cycle_cnt[6:1];
    end
    endcase
end

always @(*) begin
    case(mode)
    `NTT, 
    `INVNTT: begin
        raddr = raddr_offset + cycle_cnt[4:1] + (cycle_cnt[0] ? stage_offset : 5'd0);
    end
    default: begin // `MULT, `ADDSUB
        raddr = raddr_offset;
    end
    endcase
end

always @(*) begin
    case(mode)
    `NTT: begin
       coef_addr = coef_addr_offset + coef_addr_cnt;
    end
    `INVNTT: begin
       coef_addr = coef_addr_offset - coef_addr_cnt;
    end
    `MULT: begin
        coef_addr = coef_addr_offset + coef_addr_cnt;
    end
    `ADDSUB: begin
        coef_addr = 0;
    end
    endcase
end

integer i;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i=0; i<6; i=i+1) waddr_shift_reg[i] <= 0;
    end
    else begin
        case(mode)
        `NTT, 
        `INVNTT: begin
        waddr_shift_reg[0] <= raddr;
        for(i=1; i<6; i=i+1) waddr_shift_reg[i] <= waddr_shift_reg[i-1];
        end
        endcase
    end
end


always @(*) begin
    case(mode)
    `NTT, 
    `INVNTT: begin
       waddr = waddr_shift_reg[5];
    end
    `MULT: begin
       waddr = cycle_cnt[7:2] - 3;
    end
    `ADDSUB: begin
       waddr = cycle_cnt[7:1] - 2;
    end
    endcase
end

endmodule