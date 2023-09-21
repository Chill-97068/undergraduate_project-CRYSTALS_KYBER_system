`include "../Hash/KECCAK_p.v"
//G
module SHA3_512(input [0:256-1] M,
                input active, //Let stage go to s1 
                input clk, rst,
                output reg [0:512-1] Z);

parameter d_SIZE = 512,
          c_SIZE = 1024,
          r_SIZE = 576, //r=b-c
          M_SIZE = 256;
parameter j = 316;//j=r_SIZE - (M_SIZE+2+2)

wire [0:(M_SIZE+2)-1] N;
wire [0:((M_SIZE+2)+1+j+1)-1] P;
wire [4:0] nr;
wire [0:1599] str_out;
wire [2:0] cnt;//counter+1
wire [11:0] counter_r_r_SIZE;//counter_r-r_SIZE
reg [2:0] cs,ns;
reg string_val;
reg [0:1599] str, str_temp, str_temp2;
reg [2:0] counter;  //0~n-1
reg [4:0] counter_f;//count rnds of KECCAK_p
reg [11:0] counter_r;//count times of Z=Z||Trunc_r(S)
reg [0:(r_SIZE*2)-1] Z_temp;// r*2 bits

assign N ={M,2'b01}; //N=M||01
assign nr = 5'd24;   //nr=24

//pad10*1(r,len(N))
assign P = {N,1'b1,{j{1'b0}},1'b1};
//
parameter n = 1;//n=len(P)/r = (256+2+1+316+1)/576 = 1
assign cnt = counter + 3'd1;//counter+1
assign counter_r_r_SIZE = counter_r-r_SIZE;

parameter s0 = 3'b000,
          s1 = 3'b001,
          s2 = 3'b010,
          s3 = 3'b011,
          s4 = 3'b100,
          s5 = 3'b101,
          s6 = 3'b110,
          s7 = 3'b111;

KECCAK_p keccak_p( .S(str_temp),
                   .nr(nr),
                   .string_val(string_val),
                   .clk(clk), .rst(rst),
                   .S_out(str_out));

always@(posedge clk or posedge rst)begin
        if(rst)begin
            cs <= s0;
            str_temp <= 1600'd0;
            str_temp2 <= 1600'd0;
            counter <= 3'd0;
            counter_f <= 5'd0;
            counter_r <= 12'd0;
            Z_temp <= {r_SIZE*3{1'b0}};

        end
        else begin
            cs <= ns;
            //str_temp= S^(Pi||c(0))
            if(ns == s1)begin
                str_temp <= str^{P[counter+:r_SIZE],{c_SIZE{1'b0}}};
            end
            else if(ns == s4) begin
                str_temp <= str_temp2;
            end
            else begin
                str_temp <= str_temp;
            end
            
            
            //let S equal to str_out after do a S=f(S^(Pi||c(0))) and S=f(S)
            str_temp2 <= (cs == s2 || cs == s5)? str_out:str_temp2;

            counter <= (cs == s2)? counter+3'd1 : counter;
            counter_r <= (ns == s3 || ns==s6)? counter_r+r_SIZE:counter_r;//+r_SIZE
            
            //counter_f
            if((cs == s1)||(cs == s4))begin
                counter_f <= counter_f+5'd1;
            end
            else if((ns == s1) || (ns==s4))begin
                counter_f <= 5'd0;
            end
            else begin
                counter_f <= counter_f;
            end

            //Z=Z||Trunc_r(S)
            if(cs == s3 || cs == s6)begin
                Z_temp[counter_r_r_SIZE +:r_SIZE] <= str_temp2[0:r_SIZE-1];
            end
            else begin
                Z_temp[counter_r_r_SIZE +:r_SIZE] <= Z_temp[counter_r_r_SIZE +:r_SIZE];
            end

        end

end
            


always@(cs or active or counter_f or cnt or counter_r)begin
	//next stage
	case(cs)
		s0: ns = (active)? s1:s0;
		s1: ns = (counter_f== 5'd25) ? s2:s1;//S=f(S^(Pi||c(0)))
		s2: ns = (cnt == n) ? s3:s1; //counter is from 0 to n-1
        s3: ns = (counter_r >= d_SIZE)?s7:s4;//determine if d<=|Z|
        s4: ns = (counter_f == 5'd25) ?s5:s4;//S=f(S)
        s5: ns = s6;
        s6: ns = (counter_r >= d_SIZE)?s7:s4;//determine if d<=|Z|
        s7: ns = s7;//output
		default: ns = s0;
	endcase	
end

always@(cs or counter or str_temp2)begin
    case(cs)
		s0: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b0;
                str = 1600'd0;
            end    
		s1: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                if(counter==3'd0)begin
                    str = 1600'd0;
                end
                else begin
                    str = str_temp2;
                end
            end
		s2: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
            end
        s3: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b0;
                str = str_temp2;
            end
        s4: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
            end
        s5: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b1;//string_val=1
                str = str_temp2;
            end
        s6: begin
                Z = Z_temp[0:d_SIZE-1];
                string_val = 1'b0;
                str = str_temp2;
            end
        s7: begin
                Z = Z_temp[0:d_SIZE-1]; //Z=Trunc_d(Z)
                string_val = 1'b0;
                str = str_temp2;
            end
		default: begin
                Z = {d_SIZE{1'd0}};
                string_val = 1'b0;
                str = str_temp2;
            end
    endcase
end

endmodule