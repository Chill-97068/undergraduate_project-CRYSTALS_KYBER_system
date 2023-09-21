
module buf_96x32 (
    input clk,
    input rst,
    input wen,
    input [4:0] raddr,
    input [4:0] waddr,
    input [95:0] din,
    output reg [95:0] dout
);

reg [95:0] data [0:31];

always @(*) begin
    dout = data[raddr];
end

integer i;
always@(posedge clk) begin
    if(rst) begin
        for(i=0; i<32; i=i+1) data[i] <= 0;
    end
    else begin
        if(wen) data[waddr] <= din;
    end
end

endmodule