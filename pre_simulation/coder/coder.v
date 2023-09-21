`include "../coder/compress.v"
`include "../coder/decompress.v"

module coder (
    input clk,
    input rst,
    input active,
    input load_input_Enc,
    input load_input_Dec,
    input [3:0] mode, 
   
    input [6399:0] pk_in, // 12*256*2 + 256
    input [255:0] m_in, 
    input [6143:0] sk_in, // 12*256*2
    input [6143:0] c_in, // 10*256*2 + 4*256
    
    output [6399:0] pk_out, // 12*256*2 + 256
    output [255:0] m_out, 
    output [6143:0] sk_out, // 12*256*2
    output [6143:0] c_out, // 10*256*2 + 4*256

    input [255:0] rho_from_G,
    output [255:0] rho_from_pk,
    output reg ram_wen,
    output reg [7:0] ram_raddr,
    output reg [7:0] ram_waddr, 
    input [95:0] ram_rdata,
    output reg [95:0] ram_wdata

);

// ram offset
parameter ram_0_offset = 8'd0;
parameter ram_1_offset = 8'd32;
parameter ram_2_offset = 8'd64;
parameter ram_3_offset = 8'd96;
parameter ram_4_offset = 8'd128;
parameter ram_5_offset = 8'd160;
parameter ram_6_offset = 8'd192;
parameter ram_7_offset = 8'd224;

// mode define
parameter WAIT = 4'd0;
parameter KeyGen_encode_sk = 4'd1; // 65 cycle (active 1 + working 64)
parameter KeyGen_encode_pk = 4'd2; // 65 cycle (active 1 + working 64)
parameter Enc_decode_pk = 4'd3; // 65 cycle (active 1 + working 64)
parameter Enc_decode_m = 4'd4; // 34 cycle (active 1 + working 33)
parameter Enc_encode_c = 4'd5; // 98 cycle (active 1 + working 97)
parameter Dec_decode_sk = 4'd6; // 65 cycle (active 1 + working 64)
parameter Dec_decode_c = 4'd7; // 98 cycle (active 1 + working 97)
parameter Dec_encode_m = 4'd8; // 34 cycle (active 1 + working 33)

// registers
reg [3:0] mode_reg;
reg [6:0] cnt;
reg [6143:0] t_c_reg; // store t at Key_gen, store t/c at Enc, store  c  at Dec
reg [6143:0] s_m_reg; // store s at Key_gen, store  m  at Enc, store s/m at Dec
reg [255:0] rho_reg;

// 
reg [3:0] d;
wire [7:0] comp_out_d1;
wire [31:0] comp_out_d4;
wire [79:0] comp_out_d10;
reg [7:0] decomp_in_d1;
reg [31:0] decomp_in_d4;
reg [79:0] decomp_in_d10;
wire [95:0] decomp_out_data;
reg last_cycle;

compress comp (
    .clk(clk),
    .rst(rst),
    .d(d), 
    .in_data(ram_rdata),
    .out_data_d1(comp_out_d1),
    .out_data_d4(comp_out_d4),
    .out_data_d10(comp_out_d10)
);

decompress decomp (
    .clk(clk),
    .rst(rst),
    .d(d),
    .in_data_d1(decomp_in_d1),
    .in_data_d4(decomp_in_d4),
    .in_data_d10(decomp_in_d10),
    .out_data(decomp_out_data)
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        mode_reg <= WAIT;
        cnt <= 7'd0;
    end
    else begin
        if(active) begin
            mode_reg <= mode;
            cnt <= 7'd0;
        end
        else if(last_cycle) begin
            mode_reg <= WAIT;
            cnt <= 7'd0;
        end
        else if(mode_reg != WAIT) begin
            cnt <= cnt + 7'd1;
        end
    end
end

// output wires
assign pk_out = { t_c_reg, rho_reg };
assign m_out = s_m_reg[255:0];
assign sk_out = s_m_reg;
assign c_out = t_c_reg;
assign rho_from_pk = rho_reg[255:0];

// register wires
reg [95:0] t_c_reg_t_in [0:63];
wire [95:0] t_c_reg_t [0:63];

reg [79:0] t_c_reg_u_in [0:63];
wire [79:0] t_c_reg_u [0:63];

reg [31:0] t_c_reg_v_in [0:31];
wire [31:0] t_c_reg_v [0:31];

reg [95:0] s_m_reg_s_in [0:63];
wire [95:0] s_m_reg_s [0:63];

reg [7:0] s_m_reg_m_in [0:31];
wire [7:0] s_m_reg_m [0:31];

genvar i1;
generate
    for(i1=0; i1<64; i1=i1+1) begin
        assign t_c_reg_t[i1] = t_c_reg[(i1*96+95):(i1*96)];
        assign t_c_reg_u[i1] = t_c_reg[(i1*80+79):(i1*80)];
        assign s_m_reg_s[i1] = s_m_reg[(i1*96+95):(i1*96)];
    end
    for(i1=0; i1<32; i1=i1+1) begin
        assign t_c_reg_v[i1] = t_c_reg[(i1*32+80*64+31):(i1*32+80*64)];
        assign s_m_reg_m[i1] = s_m_reg[(i1*8+7):(i1*8)];
    end
endgenerate

integer i2;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        t_c_reg <= 6144'd0;
        s_m_reg <= 6144'd0;
        rho_reg <= 256'd0;
    end
    else if(load_input_Enc) begin
        rho_reg <= pk_in[255:0];
        t_c_reg <= pk_in[6399:256];
        s_m_reg <= m_in;
    end
    else if(load_input_Dec) begin
        t_c_reg <= c_in;
        s_m_reg <= sk_in;
    end
    else begin
        case(mode_reg)
        KeyGen_encode_sk: 
            for(i2=0; i2<64; i2=i2+1)
                s_m_reg[i2*96 +: 96] <= s_m_reg_s_in[i2];
        KeyGen_encode_pk: begin
            if(cnt == 4'd0) rho_reg <= rho_from_G;
            for(i2=0; i2<64; i2=i2+1)
                t_c_reg[i2*96 +: 96] <= t_c_reg_t_in[i2];
        end
        Enc_encode_c: begin
            for(i2=0; i2<64; i2=i2+1)
                t_c_reg[i2*80 +: 80] <= t_c_reg_u_in[i2];
            for(i2=0; i2<32; i2=i2+1)
                t_c_reg[(i2*32+80*64) +: 32] <= t_c_reg_v_in[i2];
        end
        Dec_encode_m:
            for(i2=0; i2<32; i2=i2+1)
                s_m_reg[i2*8 +: 8] <= s_m_reg_m_in[i2];
        endcase
    end
end

always @(*) begin
    ram_wen = 1'b0;
    ram_raddr = 7'd0;
    ram_waddr = 7'd0;
    ram_wdata = 8'd0;
    d = 4'd1;
    decomp_in_d1 = 8'd0;
    decomp_in_d4 = 32'd0;
    decomp_in_d10 = 80'd0;
    last_cycle = 1'b0;
    for(i2=0; i2<64; i2=i2+1) begin
        t_c_reg_t_in[i2] = t_c_reg_t[i2];
        t_c_reg_u_in[i2] = t_c_reg_u[i2];
        s_m_reg_s_in[i2] = s_m_reg_s[i2];
    end
    for(i2=0; i2<32; i2=i2+1) begin
        t_c_reg_v_in[i2] = t_c_reg_v[i2];
        s_m_reg_m_in[i2] = s_m_reg_m[i2];
    end
    case(mode_reg)
        KeyGen_encode_sk: begin
            ram_raddr = ram_4_offset + cnt;
            s_m_reg_s_in[cnt] = ram_rdata;
            last_cycle = cnt == 7'd63;
        end
        KeyGen_encode_pk: begin
            ram_raddr = ram_6_offset + cnt;
            t_c_reg_t_in[cnt] = ram_rdata;
            last_cycle = cnt == 7'd63;
        end
        Enc_decode_pk: begin
            ram_wen = 1'b1;
            ram_waddr = ram_0_offset + cnt;
            ram_wdata = t_c_reg_t[cnt];
            last_cycle = cnt == 7'd63;
        end
        Enc_decode_m: begin
            ram_wen = cnt != 7'd0 ? 1'b1 : 1'b0;
            ram_waddr = ram_3_offset + cnt - 8'd1;
            ram_wdata = decomp_out_data;
            d = 4'd1;
            decomp_in_d1 = s_m_reg_m[cnt];
            last_cycle = cnt == 7'd32;
        end
        Enc_encode_c: begin
            if(cnt == 7'd0) begin
                d = 4'd10;
                ram_raddr = ram_6_offset + cnt;
            end
            else if(cnt < 7'd64) begin
                d = 4'd10;
                ram_raddr = ram_6_offset + cnt;
                t_c_reg_u_in[cnt-1] = comp_out_d10;
            end
            else if(cnt == 7'd64) begin
                d = 4'd4;
                ram_raddr = ram_0_offset + cnt - 7'd64;
                t_c_reg_u_in[cnt-1] = comp_out_d10;
            end
            else begin
                d = 4'd4;
                ram_raddr = ram_0_offset + cnt - 7'd64;
                t_c_reg_v_in[cnt-65] = comp_out_d4;
            end
            last_cycle = cnt == 7'd96;
        end
        Dec_decode_sk: begin
            ram_wen = 1'b1;
            ram_waddr = ram_3_offset + cnt;
            ram_wdata = s_m_reg_s[cnt];
            last_cycle = cnt == 7'd63;
        end
        Dec_decode_c: begin
            ram_wen = cnt != 7'd0 ? 1'b1 : 1'b0;
            ram_waddr = ram_0_offset + cnt - 8'd1;
            ram_wdata = decomp_out_data;
            d = cnt < 7'd64 ? 4'd10 : 4'd4;
            decomp_in_d10 = t_c_reg_u[cnt];
            decomp_in_d4 = t_c_reg_v[cnt-64];
            last_cycle = cnt == 7'd96;
        end
        Dec_encode_m: begin
            ram_raddr = ram_0_offset + cnt;
            s_m_reg_m_in[cnt-1] = comp_out_d1;
            last_cycle = cnt == 7'd32;
        end
    endcase
end

endmodule