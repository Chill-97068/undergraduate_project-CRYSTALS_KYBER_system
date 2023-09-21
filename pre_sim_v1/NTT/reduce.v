module reduce (
    input clk,
    input rst,
    input [23:0] c,
    output [11:0] r
);

// segment 1
// Calculate Q'1 (Q_1) with low-complexity division by 13.
wire [7:0] c0;
wire [15:0] c1;
wire [13:0] d_1;
wire [13:0] d1_sum;
wire [12:0] Q_1;
assign c0 = c[7:0];
assign c1 = c[23:8];
assign d_1 = c1[15:3] + c1[15:5]; 
assign d1_sum = d_1 - d_1[13:6];
assign Q_1 = d1_sum[13:1];

// stage 1 registers
reg [7:0] c0_reg;
reg [5:0] c1_reg;
reg [12:0] Q_1_reg;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        Q_1_reg <= 0;
        c1_reg <= 0;
        c0_reg <= 0;
    end
    else begin
        Q_1_reg <= Q_1;
        c1_reg <= c1[5:0];
        c0_reg <= c0;
    end
end

// segment 2
// Calculate r'1 (r_1) ~= c1 mod13 with a short width addition tree.
wire [5:0] s_1;
wire [5:0] s_2;
wire [5:0] r_1;
wire [13:0] r1c0;
assign s_1[5:3] = c1_reg[5:3] - Q_1_reg[2:0];
assign s_1[2:0] = c1_reg[2:0];
assign s_2[5:2] = Q_1_reg[5:2] + Q_1_reg[3:0];
assign s_2[1:0] = Q_1_reg[1:0];
assign r_1 = s_1 - s_2;
assign r1c0 = {r_1, c0_reg};

// segment 3
// Obtain raw remander R and calculate r = R mod 3329.
wire [13:0] R;
reg [13:0] R_reg;
assign R = r1c0 - Q_1_reg;
always @(posedge clk or posedge rst) begin
    if(rst) R_reg = 0;
    else R_reg <= R;
end
assign r = R_reg[13] | (R_reg[12:0] >= 13'd3329) ? 
                       (R_reg[11:0] + (R_reg[13] ? 12'd3329 : -12'd3329))
                     : R_reg[11:0];

    
endmodule