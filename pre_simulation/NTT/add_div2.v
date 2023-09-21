/*
    12-bit addition or add->div_by_2 into 12 bit reduced result
    mode == 1       -> div 2
    mode == else    -> not div 2   
*/

module add_div2 (
    input [11:0] in1,
    input [11:0] in2,
    input [1:0] mode,
    output [11:0] res
);

wire [12:0] add_result;
wire [11:0] reduced_add_result;

assign add_result = in1 + in2;
assign reduced_add_result = add_result >= 13'd3329 ? add_result - 12'd3329 : add_result;
assign res = mode == 2'd1 ?  (reduced_add_result[0]/*odd?*/ ? reduced_add_result[11:1] + 12'd1665 : reduced_add_result[11:1] )
           /*mode != 2'd1*/: reduced_add_result;
endmodule