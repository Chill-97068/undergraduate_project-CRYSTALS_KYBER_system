`include "../NTT/mul_reduce.v"
`include "../NTT/add_div2.v"
`include "../NTT/sub_div2.v"

module BU (
    input clk,
    input rst,
    input [11:0] u_in,
    input [11:0] t_in,
    input [11:0] coef,
    input [1:0] mode,
    output [11:0] U_out,
    output [11:0] T_out
);

/*
mode 0: NTT & mul_stage_2 (mul reduce -> add sub, total 5 delay)
mode 1: INVNTT (add sub -> mul reduce, total 5 delay)
mode 2: mul_stage_1 (mul reduce only, total 4 delay)
mode 3: add or sub poly (add sub only, total 1 delay)

*/

// slice A
// mult & reduce
wire [11:0] slice_A_u_in;
wire [11:0] slice_A_t_in;
wire [11:0] slice_A_coef_in;
wire [11:0] slice_A_U_out;
wire [11:0] slice_A_T_out;
reg [11:0] slice_A_shift_regs [0:3];
mul_reduce mul_red_A (
    .clk(clk),
    .rst(rst),
    .in1(slice_A_t_in),
    .in2(slice_A_coef_in),
    .res(slice_A_T_out)
);
always @(posedge clk) begin
    slice_A_shift_regs[0] <= slice_A_u_in;
    slice_A_shift_regs[1] <= slice_A_shift_regs[0];
    slice_A_shift_regs[2] <= slice_A_shift_regs[1];
    slice_A_shift_regs[3] <= slice_A_shift_regs[2];
end
assign slice_A_U_out = slice_A_shift_regs[3];

// slice B
// add & sub
wire [11:0] slice_B_u_in;
wire [11:0] slice_B_t_in;
wire [11:0] slice_B_U_out;
wire [11:0] slice_B_T_out;
reg [11:0] slice_B_u_in_reg;
reg [11:0] slice_B_t_in_reg;
add_div2 add_B (
    .in1(slice_B_u_in_reg),
    .in2(slice_B_t_in_reg),
    .mode(mode),
    .res(slice_B_U_out)
);
sub_div2 sub_B (
    .in1(slice_B_u_in_reg),
    .in2(slice_B_t_in_reg),
    .mode(mode),
    .res(slice_B_T_out)
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        slice_B_u_in_reg <= 0;
        slice_B_t_in_reg <= 0;
    end
    else begin
        slice_B_u_in_reg <= slice_B_u_in;
        slice_B_t_in_reg <= slice_B_t_in;
    end
end

// input select multiplexers
reg [11:0] coef_reg;
always @(posedge clk) begin
    if(rst) coef_reg <= 0;
    else coef_reg <= coef;
end
assign slice_A_u_in = mode == 2'd1 || mode == 2'd3 ? slice_B_U_out : u_in;
assign slice_A_t_in = mode == 2'd1 || mode == 2'd3 ? slice_B_T_out : t_in;
assign slice_A_coef_in = mode == 2'd1 || mode == 2'd3 ? coef_reg : coef;
assign slice_B_u_in = mode == 2'd1 || mode == 2'd3 ? u_in : slice_A_U_out;
assign slice_B_t_in = mode == 2'd1 || mode == 2'd3 ? t_in : slice_A_T_out;

// output select multiplexers
assign U_out = mode == 2'd0 || mode == 2'd3 ? slice_B_U_out : slice_A_U_out;
assign T_out = mode == 2'd0 || mode == 2'd3 ? slice_B_T_out : slice_A_T_out;
    
endmodule