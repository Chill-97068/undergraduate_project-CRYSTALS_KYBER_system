module compress (
    input clk,
    input rst,
    input [3:0] d,     
    input [95:0] in_data,
    output [7:0] out_data_d1,
    output [31:0] out_data_d4,
    output [79:0] out_data_d10
);

// input reg
integer i;
reg [11:0] in_reg [0:7];
reg [23:0] mul_out [0:7];

always @(posedge clk or posedge rst) begin
    if(rst) for(i=0; i<8; i=i+1) in_reg[i] <= 12'd0;
    else begin
        in_reg[0] <= in_data[11:00];
        in_reg[1] <= in_data[23:12];
        in_reg[2] <= in_data[35:24];
        in_reg[3] <= in_data[47:36];
        in_reg[4] <= in_data[59:48];
        in_reg[5] <= in_data[71:60];
        in_reg[6] <= in_data[83:72];
        in_reg[7] <= in_data[95:84];
    end
end

always @(*) begin
    for(i=0; i<8; i=i+1) mul_out[i] = in_reg[i] * 12'd2519; // 2519 = (2<<22)/3329 = (16<<19)/3329 = (1024<<13)/3329
end

//assign out_data_d1 = {  mul_out[7][22], mul_out[6][22], mul_out[5][22], mul_out[4][22], 
//                        mul_out[3][22], mul_out[2][22], mul_out[1][22], mul_out[0][22] } ; // mul_out >> 22
//
assign out_data_d1[7] = in_reg[7] > 12'd832 && in_reg[7] < 12'd2496;
assign out_data_d1[6] = in_reg[6] > 12'd832 && in_reg[6] < 12'd2496;
assign out_data_d1[5] = in_reg[5] > 12'd832 && in_reg[5] < 12'd2496;
assign out_data_d1[4] = in_reg[4] > 12'd832 && in_reg[4] < 12'd2496;
assign out_data_d1[3] = in_reg[3] > 12'd832 && in_reg[3] < 12'd2496;
assign out_data_d1[2] = in_reg[2] > 12'd832 && in_reg[2] < 12'd2496;
assign out_data_d1[1] = in_reg[1] > 12'd832 && in_reg[1] < 12'd2496;
assign out_data_d1[0] = in_reg[0] > 12'd832 && in_reg[0] < 12'd2496;

assign out_data_d4 = {  mul_out[7][22:19], mul_out[6][22:19], mul_out[5][22:19], mul_out[4][22:19], 
                        mul_out[3][22:19], mul_out[2][22:19], mul_out[1][22:19], mul_out[0][22:19] } ; // mul_out >> 19

assign out_data_d10 = { mul_out[7][22:13], mul_out[6][22:13], mul_out[5][22:13], mul_out[4][22:13], 
                        mul_out[3][22:13], mul_out[2][22:13], mul_out[1][22:13], mul_out[0][22:13] } ; // mul_out >> 13

endmodule