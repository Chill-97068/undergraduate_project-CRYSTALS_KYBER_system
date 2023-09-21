
`include"controller.v"
`include"ram_96x256.v"
`include"../Hash/SHA3_512.v"
`include"../Hash/A_generator.v"
`include"../Hash/small_poly_generator.v"
`include"../NTT/ntt_processor.v"
`include"../coder/coder.v"

module top(
    input clk,
    input rst,
    input start,
    input [1:0] mode,
    input [255:0] random_coin,

    input [255:0] m_in,
    input [6399:0]pk_in,// 12*256*2 + 256
    input [6143:0]sk_in,// 12*256*2
    input [6143:0]c_in, // 10*256*2 + 4*256

    output [255:0] m_out,
    output [6399:0]pk_out,// 12*256*2 + 256
    output [6143:0]sk_out,// 12*256*2
    output [6143:0]c_out, // 10*256*2 + 4*256

    output finish
);

//controller
wire ntt_start, ntt_is_add_or_sub;
wire [1:0] ntt_mode;
wire [7:0]  ntt_ram_r_start_offset_A, ntt_ram_r_start_offset_B, ntt_ram_w_start_offset;

wire G_active, G_rst;

wire CBD_rst, CBD_active;
wire [1:0] CBD_num;
wire [7:0] CBD_ram_w_start_offset, CBD_diff;

wire A_gen_rst, A_gen_active;
wire [7:0] A_gen_ram_w_start_offset;
wire [15:0] A_gen_diff;

wire coder_active, coder_load_input_Enc, coder_load_input_Dec;
wire [3:0] coder_mode;

wire CBD_in_sel, rho_sel, ram_r_sel;
wire [1:0] ram_w_sel;

//G
wire [255:0] G_rho, G_sigma;

//A_gen
wire A_wen;
wire [7:0] A_waddr;
wire [95:0] A_wdata;

reg [255:0] rho_temp;

//CBD
wire CBD_wen;
wire [7:0] CBD_waddr;
wire [95:0] CBD_wdata; 

reg [255:0] CBD_input;

//ntt
wire ntt_wen, ntt_last_cycle;
wire [7:0] ntt_raddr, ntt_waddr;
wire [95:0] ntt_wdata;

//coder
wire [255:0] rho_from_pk;
wire coder_wen;
wire [7:0] coder_raddr, coder_waddr;
wire [95:0] coder_wdata;

//ram
wire [95:0] RAM_rdata;

reg wen_temp;
reg [7:0] raddr_temp, waddr_temp;
reg [95:0] wdata_temp;

controller control(
    .clk(clk),
    .rst(rst),
    .start(start),
    .mode(mode),
    .finish(finish),

    .ntt_start(ntt_start),
    .ntt_mode(ntt_mode),
    .ntt_is_add_or_sub(ntt_is_add_or_sub),
    .ntt_ram_r_start_offset_A(ntt_ram_r_start_offset_A),
    .ntt_ram_r_start_offset_B(ntt_ram_r_start_offset_B),
    .ntt_ram_w_start_offset(ntt_ram_w_start_offset),

    .G_active(G_active),
    .G_rst(G_rst),

    .CBD_rst(CBD_rst),
    .CBD_active(CBD_active),
    .CBD_num(CBD_num),
    .CBD_ram_w_start_offset(CBD_ram_w_start_offset),
    .CBD_diff(CBD_diff),

    .A_gen_rst(A_gen_rst),
    .A_gen_active(A_gen_active),
    .A_gen_ram_w_start_offset(A_gen_ram_w_start_offset),
    .A_gen_diff(A_gen_diff),

    .coder_active(coder_active),
    .coder_load_input_Enc(coder_load_input_Enc),
    .coder_load_input_Dec(coder_load_input_Dec),
    .coder_mode(coder_mode),

    .CBD_in_sel(CBD_in_sel),
    .rho_sel(rho_sel),
    .ram_r_sel(ram_r_sel),
    .ram_w_sel(ram_w_sel)
);

SHA3_512 G( .M(random_coin),
            .active(G_active),
            .clk(clk),.rst(G_rst),
            .Z({G_rho,G_sigma}));


A_generator A_gen(  .M({rho_temp,A_gen_diff}),
                    .ram_w_start_offset(A_gen_ram_w_start_offset), 
                    .clk(clk),.rst(A_gen_rst), .active(A_gen_active),
                    .enw(A_wen),
                    .waddr(A_waddr),
                    .dout(A_wdata));

                    
small_poly_generator CBD(   .M({CBD_input,CBD_diff}), 
                            .ram_w_start_offset(CBD_ram_w_start_offset),
                            .n_num(CBD_num), 
                            .clk(clk),.rst(CBD_rst), .active(CBD_active),
                            .enw(CBD_wen),
                            .waddr(CBD_waddr),
                            .dout(CBD_wdata)); 


ntt_processer ntt(
    .clk(clk),
    .rst(rst),
    .start(ntt_start),
    .mode(ntt_mode),
    .is_add_or_sub(ntt_is_add_or_sub),
    .ram_r_start_offset_A(ntt_ram_r_start_offset_A),
    .ram_r_start_offset_B(ntt_ram_r_start_offset_B),
    .ram_w_start_offset(ntt_ram_w_start_offset),
    .ram_rdata(RAM_rdata),
    .last_cycle(ntt_last_cycle),
    .ram_wen(ntt_wen),
    .ram_raddr(ntt_raddr),
    .ram_waddr(ntt_waddr),
    .ram_wdata(ntt_wdata)
);

coder code(
    .clk(clk),
    .rst(rst),
    .active(coder_active),
    .load_input_Enc(coder_load_input_Enc),
    .load_input_Dec(coder_load_input_Dec),
    .mode(coder_mode), 
   
    .pk_in(pk_in), 
    .m_in(m_in), 
    .sk_in(sk_in),
    .c_in(c_in), 
    
    .pk_out(pk_out), 
    .m_out(m_out), 
    .sk_out(sk_out), 
    .c_out(c_out), 

    .rho_from_G(G_rho),
    .rho_from_pk(rho_from_pk),
    .ram_wen(coder_wen),
    .ram_raddr(coder_raddr),
    .ram_waddr(coder_waddr), 
    .ram_rdata(RAM_rdata),
    .ram_wdata(coder_wdata)

);

ram_96x256 ram(
    .clk(clk),
    .rst(rst),
    .wen(wen_temp),
    .raddr(raddr_temp),
    .waddr(waddr_temp),
    .din(wdata_temp),
    .dout(RAM_rdata)
);

always@(*)begin
    case(rho_sel)
        1'b0:begin
            rho_temp = G_rho;
        end
        1'b1:begin
            rho_temp = rho_from_pk;
        end
    endcase

    case(CBD_in_sel)
        1'b0:begin
            CBD_input = G_sigma;
        end
        1'b1:begin
            CBD_input = random_coin;
        end
    endcase

    case(ram_r_sel)
        1'b0:begin
            raddr_temp = coder_raddr;
        end
        1'b1:begin
            raddr_temp = ntt_raddr;
        end
    endcase

    case(ram_w_sel)
        2'd0:begin
            wen_temp = coder_wen;
            waddr_temp = coder_waddr;
            wdata_temp = coder_wdata;
        end
        2'd1:begin
            wen_temp = ntt_wen;
            waddr_temp = ntt_waddr;
            wdata_temp = ntt_wdata;
        end
        2'd2:begin
            wen_temp = A_wen;
            waddr_temp = A_waddr;
            wdata_temp = A_wdata;
        end
        2'd3:begin
            wen_temp = CBD_wen;
            waddr_temp = CBD_waddr;
            wdata_temp = CBD_wdata;        
        end
    endcase
end


endmodule