/*
    12-bit substraction or sub->div_by_2 into 12 bit reduced result
    mode == 1       -> div 2
    mode == else    -> not div 2   
*/

module sub_div2 (
    input [11:0] in1,
    input [11:0] in2,
    input [1:0] mode,
    output [11:0] res
);

wire [12:0] sub_result;
wire [11:0] reduced_sub_result;

assign sub_result = in1 - in2;
assign reduced_sub_result = sub_result[12]/*negative?*/ ? sub_result + 12'd3329 : sub_result;
assign res = mode == 2'd1 ?  (reduced_sub_result[0]/*odd?*/ ? reduced_sub_result[11:1] + 12'd1665 : reduced_sub_result[11:1] )
           /*mode != 2'd1*/: reduced_sub_result;
endmodule