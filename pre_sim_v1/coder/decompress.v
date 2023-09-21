module decompress (
    input clk,
    input rst,
    input [3:0] d,     
    input [7:0] in_data_d1,
    input [31:0] in_data_d4,
    input [79:0] in_data_d10,
    output [95:0] out_data
);

// input reg
integer i;
reg [11:0] in_reg [0:7];
reg [21:0] mul_out [0:7];
reg [3:0] d_reg;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        for(i=0; i<8; i=i+1) in_reg[i] <= 12'd0;
        d_reg <= 0;
    end
    else begin
        d_reg <= d;
        if(d == 4'd1) begin
            in_reg[0] <= in_data_d1[0];
            in_reg[1] <= in_data_d1[1];
            in_reg[2] <= in_data_d1[2];
            in_reg[3] <= in_data_d1[3];
            in_reg[4] <= in_data_d1[4];
            in_reg[5] <= in_data_d1[5];
            in_reg[6] <= in_data_d1[6];
            in_reg[7] <= in_data_d1[7];
        end
        else if(d == 4'd4) begin
            in_reg[0] <= in_data_d4[03:00];
            in_reg[1] <= in_data_d4[07:04];
            in_reg[2] <= in_data_d4[11:08];
            in_reg[3] <= in_data_d4[15:12];
            in_reg[4] <= in_data_d4[19:16];
            in_reg[5] <= in_data_d4[23:20];
            in_reg[6] <= in_data_d4[27:24];
            in_reg[7] <= in_data_d4[31:28];
        end
        else begin // d == 10
            in_reg[0] <= in_data_d10[09:00];
            in_reg[1] <= in_data_d10[19:10];
            in_reg[2] <= in_data_d10[29:20];
            in_reg[3] <= in_data_d10[39:30];
            in_reg[4] <= in_data_d10[49:40];
            in_reg[5] <= in_data_d10[59:50];
            in_reg[6] <= in_data_d10[69:60];
            in_reg[7] <= in_data_d10[79:70];
        end
    end
end

always @(*) begin
    for(i=0; i<8; i=i+1) mul_out[i] = (in_reg[i] * 12'd3329) >> d_reg;
end

assign out_data = {  mul_out[7][11:0], mul_out[6][11:0], mul_out[5][11:0], mul_out[4][11:0], 
                     mul_out[3][11:0], mul_out[2][11:0], mul_out[1][11:0], mul_out[0][11:0] } ;

endmodule