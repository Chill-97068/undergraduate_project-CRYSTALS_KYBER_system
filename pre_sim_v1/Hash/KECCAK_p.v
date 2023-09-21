`ifndef KECCAK_P
`define KECCAK_P

`include "../Hash/Rnd.v"

module KECCAK_p(input [0:1599] S,
                input [4:0] nr,
                input string_val, //Let stage go to s1
                input clk, rst,
                output reg [0:1599] S_out);

wire [7:0]ir;
reg [1:0]cs,ns;
reg [4:0]counter;
reg [0:1599]A;
reg [0:1599]A_temp;
wire [0:1599]A_out;

integer x1,y1,z1, x2,y2,z2;

parameter s0 = 2'b00,
          s1 = 2'b01,
          s2 = 2'b10,
          s3 = 2'b11;

//call Rnd
assign ir = {3'd0,{counter}}-8'd1;
Rnd rnd(.S(A_temp),.ir(ir),.S_out(A_out));

always@(posedge clk or posedge rst)begin
        if(rst)begin
                cs <= s0;
                counter <= 5'd1; //set to 1
                
                A_temp <= 1600'd0;
        end
        else begin
                cs <= ns;
                //ns=s2，A => A_temp
                A_temp <= (ns ==s2)? A:A_temp;
                
                //s2=> a Rnd ; In s3 => counter=24 => ir not change
                if((cs == s2) && (counter != 5'd24))begin
                        counter <= counter+5'd1;
                end
                else if(ns == s0)begin
                        counter <= 5'd1;
                end
                else begin
                        counter <= counter;
                end

        end
end

always@(cs or nr or counter or string_val)begin
	//next state
	case(cs)
		s0: ns = (string_val)? s1:s0;
		s1: ns = s2;
		s2: ns = (counter>=nr) ? s3:s2; //nr=24
                s3: ns = s0;
		default: ns = s0;
	endcase	
end

always@(*)begin
        //state output
	case(cs)
		s0: begin
                        S_out = A_out;     
                        A=A_temp;                      
                end
                //string to A
		s1:  begin
                        S_out = A_out;
                        A=S;
                                        
                end
                //a round => Rnd; total 24 round(cycle)
		s2: begin
                        S_out = A_out;                         
                        A=A_out;
                                     
                end
                //output final value
                s3: begin
                        S_out = A_out;
                        A=A_out;
                end
		default:  begin
                        S_out = 1600'd0;
                        A=1600'd0;
                end
        endcase
end


endmodule

`endif