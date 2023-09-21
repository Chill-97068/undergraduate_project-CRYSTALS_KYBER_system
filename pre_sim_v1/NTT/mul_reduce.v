/*
    12-bit multiplication into 12 bit reduced result
    input -> input regisger -> multiplication -> product register -> reduce unit (2 pipeline stage inside)
    totally 5 pipeline stage (4 pipeline register) 
*/
`include "../NTT/reduce.v"
module mul_reduce (
    input clk,
    input rst,
    input [11:0] in1,
    input [11:0] in2,
    output [11:0] res
);

// input_reg
reg [11:0] in1_reg;
reg [11:0] in2_reg;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        in1_reg <= 0;
        in2_reg <= 0;
    end
    else begin
        in1_reg <= in1;
        in2_reg <= in2;
    end
end

// product registers
wire [23:0] prod;
assign prod = in1_reg * in2_reg;
reg [23:0] prod_reg;
always @(posedge clk or posedge rst) begin
    if(rst) prod_reg <= 0;
    else prod_reg <= prod;
end

// reduce unit
// (2 pipeline register inside)

reduce mod (
    .clk(clk),
    .rst(rst),
    .c(prod_reg),
    .r(res)
);
    
endmodule