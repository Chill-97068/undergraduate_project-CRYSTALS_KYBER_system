module controller (
    input clk,
    input rst,
    input start,
    input [1:0] mode, // 0:KeyGen, 1:Enc, 2:Dec
    output finish,
    
    output reg ntt_start,
    output reg [1:0] ntt_mode,
    output reg ntt_is_add_or_sub,
    output reg [7:0] ntt_ram_r_start_offset_A,
    output reg [7:0] ntt_ram_r_start_offset_B,
    output reg [7:0] ntt_ram_w_start_offset,

    output G_active,
    output G_rst,

    output reg CBD_rst, 
    output reg CBD_active,
    output reg [1:0] CBD_num, //1 => n1; 2 => n2
    output reg [7:0] CBD_ram_w_start_offset,
    output reg [7:0] CBD_diff,
    
    output reg A_gen_rst, 
    output reg A_gen_active,
    output reg [7:0] A_gen_ram_w_start_offset,
    output reg [15:0] A_gen_diff,
    
    output reg coder_active,
    output reg coder_load_input_Enc,
    output reg coder_load_input_Dec,
    output reg [3:0] coder_mode, 

    output CBD_in_sel, // 0:from G, 1:from random coin
    output rho_sel, // 0:from G, 1:from pk
    output reg ram_r_sel, // 0:from coder, 1:from ntt
    output reg [1:0] ram_w_sel // 0:from coder, 1:from ntt, 2:from A_gen, 3:from CBD
);

reg [1:0] state_reg;
reg [11:0] cycle_cnt, ncnt;
reg [1:0] A_gen_state;
reg [2:0] CBD_state;
reg [4:0] ntt_state;
reg [1:0] coder_state;

// mode define
parameter KeyGen = 2'd0;
parameter Enc = 2'd1;
parameter Dec = 2'd2;
parameter FINISH = 2'd3;

// A_gen_state define
parameter A_gen_st_A00 = 2'd0;
parameter A_gen_st_A01 = 2'd1;
parameter A_gen_st_A10 = 2'd2;
parameter A_gen_st_A11 = 2'd3;

// CBD_state define
parameter CBD_st_s0 = 3'd0; // KeyGen
parameter CBD_st_s1 = 3'd1; // KeyGen
parameter CBD_st_e0 = 3'd2; // KeyGen
parameter CBD_st_e1 = 3'd3; // KeyGen
parameter CBD_st_r0 = 3'd0; // Enc
parameter CBD_st_r1 = 3'd1; // Enc
parameter CBD_st_e10 = 3'd2; // Enc
parameter CBD_st_e11 = 3'd3; // Enc
parameter CBD_st_e2 = 3'd4; // Enc

// coder_state define
parameter coder_st_encode_pk = 2'd0; // KeyGen
parameter coder_st_encode_sk = 2'd1; // KeyGen
parameter coder_st_decode_pk = 2'd0; // Enc
parameter coder_st_decode_m = 2'd1; // Enc
parameter coder_st_encode_c = 2'd2; // Enc
parameter coder_st_decode_c = 2'd0; // Dec
parameter coder_st_decode_sk = 2'd1; // Dec
parameter coder_st_encode_m = 2'd2; // Dec

// ntt_state define
parameter NTT_st_NTT_s0        = 5'd0; // KeyGen
parameter NTT_st_NTT_s1        = 5'd1; // KeyGen
parameter NTT_st_MUL_A00_s0    = 5'd2; // KeyGen
parameter NTT_st_MUL_A01_s1    = 5'd3; // KeyGen
parameter NTT_st_NTT_e0        = 5'd4; // KeyGen
parameter NTT_st_ADD_t0        = 5'd5; // KeyGen
parameter NTT_st_ADD_e0        = 5'd6; // KeyGen
parameter NTT_st_MUL_A10_s0    = 5'd7; // KeyGen
parameter NTT_st_MUL_A11_s1    = 5'd8; // KeyGen
parameter NTT_st_NTT_e1        = 5'd9; // KeyGen
parameter NTT_st_ADD_t1        = 5'd10; // KeyGen
parameter NTT_st_ADD_e1        = 5'd11; // KeyGen

parameter NTT_st_NTT_r0        = 5'd0; // Enc
parameter NTT_st_NTT_r1        = 5'd1; // Enc
parameter NTT_st_MUL_A00_r0    = 5'd2; // Enc
parameter NTT_st_MUL_A10_r1    = 5'd3; // Enc
parameter NTT_st_ADD_u0        = 5'd4; // Enc
parameter NTT_st_INVNTT_u0     = 5'd5; // Enc
parameter NTT_st_ADD_e10       = 5'd6; // Enc
parameter NTT_st_MUL_A01_r0    = 5'd7; // Enc
parameter NTT_st_MUL_A11_r1    = 5'd8; // Enc
parameter NTT_st_ADD_u1        = 5'd9; // Enc
parameter NTT_st_INVNTT_u1     = 5'd10; // Enc
parameter NTT_st_ADD_e11       = 5'd11; // Enc
parameter NTT_st_MUL_t0_r0     = 5'd12; // Enc
parameter NTT_st_MUL_t1_r1     = 5'd13; // Enc
parameter NTT_st_ADD_v         = 5'd14; // Enc
parameter NTT_st_INVNTT_v      = 5'd15; // Enc
parameter NTT_st_ADD_e2        = 5'd16; // Enc
parameter NTT_st_ADD_m         = 5'd17; // Enc

parameter NTT_st_NTT_u0        = 5'd0; // Dec
parameter NTT_st_NTT_u1        = 5'd1; // Dec
parameter NTT_st_MUL_s0_u0     = 5'd2; // Dec
parameter NTT_st_MUL_s1_u1     = 5'd3; // Dec
parameter NTT_st_ADD_su        = 5'd4; // Dec
parameter NTT_st_INVNTT_su     = 5'd5; // Dec
parameter NTT_st_SUB_v_su      = 5'd6; // Dec

// ram offset define
parameter ram_0_offset = 8'd0;
parameter ram_1_offset = 8'd32;
parameter ram_2_offset = 8'd64;
parameter ram_3_offset = 8'd96;
parameter ram_4_offset = 8'd128;
parameter ram_5_offset = 8'd160;
parameter ram_6_offset = 8'd192;
parameter ram_7_offset = 8'd224;

// coder mode define
parameter coder_mode_KeyGen_encode_sk = 4'd1;
parameter coder_mode_KeyGen_encode_pk = 4'd2;
parameter coder_mode_Enc_decode_pk = 4'd3;
parameter coder_mode_Enc_decode_m = 4'd4;
parameter coder_mode_Enc_encode_c = 4'd5;
parameter coder_mode_Dec_decode_sk = 4'd6;
parameter coder_mode_Dec_decode_c = 4'd7;
parameter coder_mode_Dec_encode_m = 4'd8;

// ram_w_sel define
parameter ram_w_from_coder = 2'd0;
parameter ram_w_from_ntt = 2'd1;
parameter ram_w_from_A_gen = 2'd2;
parameter ram_w_from_CBD = 2'd3;

// cycle_cnt logic
always @(posedge clk or posedge rst) begin
    if(rst) begin
        state_reg <= FINISH;
        cycle_cnt <= 12'd0;
    end
    else begin
        cycle_cnt <= ncnt;
        if (state_reg == FINISH && start) state_reg <= mode;
        else if ( (state_reg == KeyGen && cycle_cnt == 12'd2001) || 
                  (state_reg == Enc && cycle_cnt == 12'd2654)    || 
                  (state_reg == Dec && cycle_cnt == 12'd1174)    ) state_reg <= FINISH;
    end
end
always @(*) begin
    ncnt = state_reg == FINISH ? 12'd0 : cycle_cnt + 12'd1;
end

// ntt logic
always @(*) begin
    case(cycle_cnt)
    12'd119, 12'd349, 12'd579, 12'd719,
    12'd859, 12'd1089, 12'd1157, 12'd1225,
    12'd1365, 12'd1505, 12'd1735, 12'd1803 : ntt_start = state_reg == KeyGen;
    12'd90, 12'd320, 12'd550, 12'd690,
    12'd830, 12'd898, 12'd1128, 12'd1196,
    12'd1336, 12'd1476, 12'd1544, 12'd1774,
    12'd1842, 12'd1982, 12'd2122, 12'd2190,
    12'd2420, 12'd2488 : ntt_start = state_reg == Enc;
    12'd34, 12'd264, 12'd494, 12'd634,
    12'd774, 12'd842, 12'd1072 : ntt_start = state_reg == Dec;
    default : ntt_start = 1'b0;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) CBD_state <= 5'd0;
    else begin
        case(state_reg)
        KeyGen: begin
        case(cycle_cnt)
        12'd0: ntt_state <= NTT_st_NTT_s0;
        12'd348: ntt_state <= NTT_st_NTT_s1;
        12'd578: ntt_state <= NTT_st_MUL_A00_s0;
        12'd718: ntt_state <= NTT_st_MUL_A01_s1;
        12'd858: ntt_state <= NTT_st_NTT_e0;
        12'd1088: ntt_state <= NTT_st_ADD_t0;
        12'd1156: ntt_state <= NTT_st_ADD_e0;
        12'd1224: ntt_state <= NTT_st_MUL_A10_s0;
        12'd1364: ntt_state <= NTT_st_MUL_A11_s1;
        12'd1504: ntt_state <= NTT_st_NTT_e1;
        12'd1734: ntt_state <= NTT_st_ADD_t1;
        12'd1802: ntt_state <= NTT_st_ADD_e1;
        endcase
        end
        Enc: begin
        case(cycle_cnt)
        12'd0: ntt_state <= NTT_st_NTT_r0;
        12'd319: ntt_state <= NTT_st_NTT_r1;
        12'd549: ntt_state <= NTT_st_MUL_A00_r0;
        12'd689: ntt_state <= NTT_st_MUL_A10_r1;
        12'd829: ntt_state <= NTT_st_ADD_u0;
        12'd897: ntt_state <= NTT_st_INVNTT_u0;
        12'd1127: ntt_state <= NTT_st_ADD_e10;
        12'd1195: ntt_state <= NTT_st_MUL_A01_r0;
        12'd1335: ntt_state <= NTT_st_MUL_A11_r1;
        12'd1475: ntt_state <= NTT_st_ADD_u1;
        12'd1543: ntt_state <= NTT_st_INVNTT_u1;
        12'd1773: ntt_state <= NTT_st_ADD_e11;
        12'd1841: ntt_state <= NTT_st_MUL_t0_r0;
        12'd1981: ntt_state <= NTT_st_MUL_t1_r1;
        12'd2121: ntt_state <= NTT_st_ADD_v;
        12'd2189: ntt_state <= NTT_st_INVNTT_v;
        12'd2419: ntt_state <= NTT_st_ADD_e2;
        12'd2487: ntt_state <= NTT_st_ADD_m;
        endcase
        end
        Dec: begin
        case(cycle_cnt)
        12'd0: ntt_state <= NTT_st_NTT_u0;
        12'd263: ntt_state <= NTT_st_NTT_u1;
        12'd493: ntt_state <= NTT_st_MUL_s0_u0;
        12'd633: ntt_state <= NTT_st_MUL_s1_u1;
        12'd773: ntt_state <= NTT_st_ADD_su;
        12'd841: ntt_state <= NTT_st_INVNTT_su;
        12'd1071: ntt_state <= NTT_st_SUB_v_su;
        endcase
        end
        default: ntt_state <= 5'd0;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        ntt_is_add_or_sub = 1'b0;
        case(ntt_state)
        NTT_st_NTT_s0: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_4_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_4_offset;
        end
        NTT_st_NTT_s1: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_5_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_5_offset;
        end
        NTT_st_MUL_A00_s0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_MUL_A01_s1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_NTT_e0: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_6_offset;
            ntt_ram_r_start_offset_B = ram_6_offset;
            ntt_ram_w_start_offset = ram_6_offset;
        end
        NTT_st_ADD_t0: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_1_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_ADD_e0: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_6_offset;
            ntt_ram_w_start_offset = ram_6_offset;
        end
        NTT_st_MUL_A10_s0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_2_offset;
        end
        NTT_st_MUL_A11_s1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_3_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_3_offset;
        end
        NTT_st_NTT_e1: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_7_offset;
            ntt_ram_r_start_offset_B = ram_7_offset;
            ntt_ram_w_start_offset = ram_7_offset;
        end
        NTT_st_ADD_t1: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_2_offset;
        end
        NTT_st_ADD_e1: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_7_offset;
            ntt_ram_w_start_offset = ram_7_offset;
        end
        default: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        endcase
    end
    Enc: begin
        ntt_is_add_or_sub = 1'b0;
        case(ntt_state)
        NTT_st_NTT_r0: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_4_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_4_offset;
        end
        NTT_st_NTT_r1: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_5_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_5_offset;
        end
        NTT_st_MUL_A00_r0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_MUL_A10_r1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_2_offset;
        end
        NTT_st_ADD_u0: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_2_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_INVNTT_u0: begin
            ntt_mode = 2'd1;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_ADD_e10: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_6_offset;
            ntt_ram_w_start_offset = ram_6_offset;
        end
        NTT_st_MUL_A01_r0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_MUL_A11_r1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_3_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_3_offset;
        end
        NTT_st_ADD_u1: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_3_offset;
        end
        NTT_st_INVNTT_u1: begin
            ntt_mode = 2'd1;
            ntt_ram_r_start_offset_A = ram_3_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_3_offset;
        end
        NTT_st_ADD_e11: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_3_offset;
            ntt_ram_r_start_offset_B = ram_7_offset;
            ntt_ram_w_start_offset = ram_7_offset;
        end
        NTT_st_MUL_t0_r0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_MUL_t1_r1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_5_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_ADD_v: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_1_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_INVNTT_v: begin
            ntt_mode = 2'd1;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_ADD_e2: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_2_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_ADD_m: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        default: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        endcase
    end
    Dec: begin
        ntt_is_add_or_sub = 1'b0;
        case(ntt_state)
        NTT_st_NTT_u0: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_NTT_u1: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_1_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_MUL_s0_u0: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_3_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_MUL_s1_u1: begin
            ntt_mode = 2'd2;
            ntt_ram_r_start_offset_A = ram_1_offset;
            ntt_ram_r_start_offset_B = ram_4_offset;
            ntt_ram_w_start_offset = ram_1_offset;
        end
        NTT_st_ADD_su: begin
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_1_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_INVNTT_su: begin
            ntt_mode = 2'd1;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        NTT_st_SUB_v_su: begin
            ntt_is_add_or_sub = 1'b1;
            ntt_mode = 2'd3;
            ntt_ram_r_start_offset_A = ram_2_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        default: begin
            ntt_mode = 2'd0;
            ntt_ram_r_start_offset_A = ram_0_offset;
            ntt_ram_r_start_offset_B = ram_0_offset;
            ntt_ram_w_start_offset = ram_0_offset;
        end
        endcase
    end
    default: begin
        ntt_is_add_or_sub = 1'b0;
        ntt_mode = 2'd0;
        ntt_ram_r_start_offset_A = ram_0_offset;
        ntt_ram_r_start_offset_B = ram_0_offset;
        ntt_ram_w_start_offset = ram_0_offset;
    end
    endcase
end

// G logic
assign G_active = state_reg == KeyGen && cycle_cnt == 12'd0;
assign G_rst = rst || state_reg == FINISH;

// CBD logic
always @(*) begin
    if(rst) CBD_rst = 1'b1;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd119 || cycle_cnt == 12'd578 || cycle_cnt == 12'd718 || cycle_cnt == 12'd809) CBD_rst = 1'b1;
            else CBD_rst = 1'b0;
        end
        Enc: begin
            if(cycle_cnt == 12'd90 || cycle_cnt == 12'd360 || cycle_cnt == 12'd549 || cycle_cnt == 12'd897 || cycle_cnt == 12'd960) CBD_rst = 1'b1;
            else CBD_rst = 1'b0;
        end
        default: CBD_rst = 1'b1;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        CBD_active = cycle_cnt == 12'd29 || cycle_cnt == 12'd120 || cycle_cnt == 12'd579 || cycle_cnt == 12'd719;
    end
    Enc: begin
        CBD_active = cycle_cnt == 12'd0 || cycle_cnt == 12'd91 || cycle_cnt == 12'd361 || cycle_cnt == 12'd550 || cycle_cnt == 12'd898;
    end
    default: CBD_active = 1'b0;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) CBD_state <= 3'd0;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd0) CBD_state <= CBD_st_s0;
            else if(cycle_cnt == 12'd119) CBD_state <= CBD_st_s1;
            else if(cycle_cnt == 12'd578) CBD_state <= CBD_st_e0;
            else if(cycle_cnt == 12'd718) CBD_state <= CBD_st_e1;
            else if(cycle_cnt == 12'd809) CBD_state <= 3'd0;
        end
        Enc: begin
            if(cycle_cnt == 12'd0) CBD_state <= CBD_st_r0;
            else if(cycle_cnt == 12'd90) CBD_state <= CBD_st_r1;
            else if(cycle_cnt == 12'd360) CBD_state <= CBD_st_e10;
            else if(cycle_cnt == 12'd549) CBD_state <= CBD_st_e11;
            else if(cycle_cnt == 12'd897) CBD_state <= CBD_st_e2;
            else if(cycle_cnt == 12'd960) CBD_state <= CBD_st_r0;
        end
        default: CBD_state <= 3'd0;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        CBD_num = 2'd1;
        case(CBD_state)       
        CBD_st_s0 : begin
            CBD_ram_w_start_offset = ram_4_offset;
            CBD_diff = 8'd0;
        end
        CBD_st_s1 : begin
            CBD_ram_w_start_offset = ram_5_offset;
            CBD_diff = 8'd1;            
        end
        CBD_st_e0 : begin
            CBD_ram_w_start_offset = ram_6_offset;
            CBD_diff = 8'd2;
        end
        CBD_st_e1 : begin
            CBD_ram_w_start_offset = ram_7_offset;
            CBD_diff = 8'd3;
        end
        default: begin
            CBD_ram_w_start_offset = 8'd0;
            CBD_diff = 8'd0;
        end
        endcase
    end
    Enc: begin
        case(CBD_state)     
        CBD_st_r0: begin
            CBD_num = 2'd1;
            CBD_ram_w_start_offset = ram_4_offset;
            CBD_diff = 8'd0;
        end
        CBD_st_r1: begin
            CBD_num = 2'd1;
            CBD_ram_w_start_offset = ram_5_offset;
            CBD_diff = 8'd1;
        end
        CBD_st_e10: begin
            CBD_num = 2'd2;
            CBD_ram_w_start_offset = ram_6_offset;
            CBD_diff = 8'd2;
        end
        CBD_st_e11: begin
            CBD_num = 2'd2;
            CBD_ram_w_start_offset = ram_7_offset;
            CBD_diff = 8'd3;
        end
        CBD_st_e2: begin
            CBD_num = 2'd2;
            CBD_ram_w_start_offset = ram_2_offset;
            CBD_diff = 8'd4;
        end
        default: begin
            CBD_num = 2'd1;
            CBD_ram_w_start_offset = 8'd0;
            CBD_diff = 8'd0;
        end
        endcase
    end
    default: begin
        CBD_num = 2'd1;
        CBD_ram_w_start_offset = 8'd0;
        CBD_diff = 8'd0;
    end
    endcase
end

// A_gen logic
always @(*) begin
    if(rst) A_gen_rst = 1'b1;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd151 || cycle_cnt == 12'd348 || cycle_cnt == 12'd492 || cycle_cnt == 12'd611) A_gen_rst = 1'b1;
            else A_gen_rst = 1'b0;
        end
        Enc: begin
            if(cycle_cnt == 12'd122 || cycle_cnt == 12'd241 || cycle_cnt == 12'd360 || cycle_cnt == 12'd479) A_gen_rst = 1'b1;
            else A_gen_rst = 1'b0;
        end
        default: A_gen_rst = 1'b1;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        A_gen_active = cycle_cnt == 12'd33 || cycle_cnt == 12'd152 || cycle_cnt == 12'd349 || cycle_cnt == 12'd493;
    end
    Enc: begin
        A_gen_active = cycle_cnt == 12'd4 || cycle_cnt == 12'd123 || cycle_cnt == 12'd242 || cycle_cnt == 12'd361;
    end
    default: A_gen_active = 1'b0;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) A_gen_state <= A_gen_st_A00;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd0) A_gen_state <= A_gen_st_A00;
            else if(cycle_cnt == 12'd151) A_gen_state <= A_gen_st_A01;
            else if(cycle_cnt == 12'd348) A_gen_state <= A_gen_st_A10;
            else if(cycle_cnt == 12'd492) A_gen_state <= A_gen_st_A11;
        end
        Enc: begin
            if(cycle_cnt == 12'd0) A_gen_state <= A_gen_st_A00;
            else if(cycle_cnt == 12'd122) A_gen_state <= A_gen_st_A01;
            else if(cycle_cnt == 12'd241) A_gen_state <= A_gen_st_A10;
            else if(cycle_cnt == 12'd360) A_gen_state <= A_gen_st_A11;
        end
        default: A_gen_state <= A_gen_st_A00;
        endcase
    end
end
always @(*) begin
    case(A_gen_state)
    A_gen_st_A00: begin
        A_gen_ram_w_start_offset = ram_0_offset;
        A_gen_diff = { 8'd0, 8'd0 };
    end
    A_gen_st_A01: begin
        A_gen_ram_w_start_offset = ram_1_offset;
        A_gen_diff = { 8'd0, 8'd1 };
    end
    A_gen_st_A10: begin
        A_gen_ram_w_start_offset = ram_2_offset;
        A_gen_diff = { 8'd1, 8'd0 };
    end
    A_gen_st_A11: begin
        A_gen_ram_w_start_offset = ram_3_offset;
        A_gen_diff = { 8'd1, 8'd1 };
    end
    endcase
end

// coder logic
always @(*) begin
    coder_load_input_Dec = 1'b0;
    coder_load_input_Enc = 1'b0;
    case(state_reg)
    KeyGen: begin
        coder_active = cycle_cnt == 12'd1871 || cycle_cnt == 12'd1936;
    end
    Enc: begin
        coder_load_input_Enc = cycle_cnt == 12'd0;
        coder_active = cycle_cnt == 12'd1544 || cycle_cnt == 12'd1842 || cycle_cnt == 12'd2556;
    end
    Dec: begin
        coder_load_input_Dec = cycle_cnt == 12'd0;
        coder_active = cycle_cnt == 12'd0 || cycle_cnt == 12'd98 || cycle_cnt == 12'd1140;
    end
    default: coder_active = 1'b0;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) coder_state <= 2'd0;
    else begin
        case(state_reg)
        KeyGen: begin
            if(cycle_cnt == 12'd0) coder_state <= coder_st_encode_pk;
            else if(cycle_cnt == 12'd1935) coder_state <= coder_st_encode_sk;
        end
        Enc: begin
            if(cycle_cnt == 12'd0) coder_state <= coder_st_decode_pk;
            else if(cycle_cnt == 12'd1841) coder_state <= coder_st_decode_m;
            else if(cycle_cnt == 12'd2555) coder_state <= coder_st_encode_c;
        end
        Dec: begin
            if(cycle_cnt == 12'd0) coder_state <= coder_st_decode_c;
            else if(cycle_cnt == 12'd97) coder_state <= coder_st_decode_sk;
            else if(cycle_cnt == 12'd1139) coder_state <= coder_st_encode_m;
        end
        default: coder_state <= 2'd0;
        endcase
    end
end
always @(*) begin
    case(state_reg)
    KeyGen: begin
        case(coder_state)
        coder_st_encode_pk: coder_mode = coder_mode_KeyGen_encode_pk;
        coder_st_encode_sk: coder_mode = coder_mode_KeyGen_encode_sk;
        default: coder_mode = 4'd0;
        endcase
    end
    Enc: begin
        case(coder_state)
        coder_st_decode_pk: coder_mode = coder_mode_Enc_decode_pk;
        coder_st_decode_m: coder_mode = coder_mode_Enc_decode_m;
        coder_st_encode_c: coder_mode = coder_mode_Enc_encode_c;
        default: coder_mode = 4'd0;
        endcase
    end
    Dec: begin
        case(coder_state)
        coder_st_decode_c: coder_mode = coder_mode_Dec_decode_c;
        coder_st_decode_sk: coder_mode = coder_mode_Dec_decode_sk;
        coder_st_encode_m: coder_mode = coder_mode_Dec_encode_m;
        default: coder_mode = 4'd0;
        endcase
    end
    default: coder_mode = 4'd0;
    endcase
end

// multiplexer sel logic
assign CBD_in_sel = state_reg != KeyGen;
assign rho_sel = state_reg != KeyGen;

always @(*) begin
    case(state_reg)
    KeyGen: ram_r_sel = cycle_cnt < 12'd1871;
    Enc: ram_r_sel = cycle_cnt < 12'd2556;
    Dec: ram_r_sel = cycle_cnt < 12'd1140;
    default: ram_r_sel = 1'b0;
    endcase
end

always @(*) begin
    case(state_reg)
    KeyGen: begin
        if(cycle_cnt < 12'd119) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd151) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd210) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd270) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd349) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd467) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd579) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd611) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd669) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd719) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd809) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd1871) ram_w_sel = ram_w_from_ntt;
        else ram_w_sel = ram_w_from_coder;
    end
    Enc: begin
        if(cycle_cnt < 12'd90) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd122) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd181) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd241) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd320) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd360) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd423) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd479) ram_w_sel = ram_w_from_A_gen;
        else if(cycle_cnt < 12'd550) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd612) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd898) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd960) ram_w_sel = ram_w_from_CBD;
        else if(cycle_cnt < 12'd1544) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd1609) ram_w_sel = ram_w_from_coder;
        else if(cycle_cnt < 12'd1842) ram_w_sel = ram_w_from_ntt;
        else if(cycle_cnt < 12'd1876) ram_w_sel = ram_w_from_coder;
        else if(cycle_cnt < 12'd2556) ram_w_sel = ram_w_from_ntt;
        else ram_w_sel = ram_w_from_coder;
    end
    Dec: begin
        if(cycle_cnt < 12'd163) ram_w_sel = ram_w_from_coder;
        else if(cycle_cnt < 12'd1140) ram_w_sel = ram_w_from_ntt;
        else ram_w_sel = ram_w_from_coder;
    end
    default: ram_w_sel = 1'b0;
    endcase
end

assign finish = state_reg == FINISH;
   
endmodule