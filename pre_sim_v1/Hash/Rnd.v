
`include "../Hash/Theta.v"
`include "../Hash/Rho.v"
`include "../Hash/Pi.v"
`include "../Hash/Chi.v"

module Rnd(input [0:1599]S,
        input [7:0]ir,
        output [0:1599]S_out);

wire [0:1599] S_out1,S_out2,S_out3,S_out4;
wire A_out[0:4][0:4][0:63];
wire Aout4[0:4][0:4][0:63];
reg [0:63]RC;
reg [0:7]R;
reg [0:8]R2, R2_temp;
reg [7:0]t;
integer j,i;

Theta theta(.S(S),.S_out(S_out1));
Rho rho(.S(S_out1),.S_out(S_out2));
Pi pi(.S(S_out2),.S_out(S_out3));
Chi chi(.S(S_out3),.S_out(S_out4));

always@(*)begin
    RC = 64'd0;
   
    for(j=0;j<=6;j=j+1)begin
        t = j+(ir+(ir<<2)+(ir<<1)); //t=j+7*ir
        R = 8'b10000000;

        if(t==0)begin   //if t%255=0 return 1, but tmax<255 => t=0 => 0%255=0
            RC[(2**j)-1] = 1;
        end
        else begin
            for(i=1;i<=t;i=i+1)begin
                R2 = {1'b0,{R}};
                R2_temp = R2;
                R2_temp[0]=R2[0]^R2[8];
                R2_temp[4]=R2[4]^R2[8];
                R2_temp[5]=R2[5]^R2[8];
                R2_temp[6]=R2[6]^R2[8];
                R = R2_temp[0:7];
            end
            RC[(2**j)-1] = R[0];
        end
    end
   
end

//str to state array(A[x][y][z]=S[64*(5*y+x)+z])
generate
        for(genvar zz=0;zz<64;zz=zz+1)begin: str_to_arr
                assign Aout4[0][0][zz]=S_out4[64*(5*0+0)+zz];
                assign Aout4[1][0][zz]=S_out4[64*(5*0+1)+zz];
                assign Aout4[2][0][zz]=S_out4[64*(5*0+2)+zz];
                assign Aout4[3][0][zz]=S_out4[64*(5*0+3)+zz];
                assign Aout4[4][0][zz]=S_out4[64*(5*0+4)+zz];

                assign Aout4[0][1][zz]=S_out4[64*(5*1+0)+zz];
                assign Aout4[1][1][zz]=S_out4[64*(5*1+1)+zz];
                assign Aout4[2][1][zz]=S_out4[64*(5*1+2)+zz];
                assign Aout4[3][1][zz]=S_out4[64*(5*1+3)+zz];
                assign Aout4[4][1][zz]=S_out4[64*(5*1+4)+zz];

                assign Aout4[0][2][zz]=S_out4[64*(5*2+0)+zz];
                assign Aout4[1][2][zz]=S_out4[64*(5*2+1)+zz];
                assign Aout4[2][2][zz]=S_out4[64*(5*2+2)+zz];
                assign Aout4[3][2][zz]=S_out4[64*(5*2+3)+zz];
                assign Aout4[4][2][zz]=S_out4[64*(5*2+4)+zz];

                assign Aout4[0][3][zz]=S_out4[64*(5*3+0)+zz];
                assign Aout4[1][3][zz]=S_out4[64*(5*3+1)+zz];
                assign Aout4[2][3][zz]=S_out4[64*(5*3+2)+zz];
                assign Aout4[3][3][zz]=S_out4[64*(5*3+3)+zz];
                assign Aout4[4][3][zz]=S_out4[64*(5*3+4)+zz];

                assign Aout4[0][4][zz]=S_out4[64*(5*4+0)+zz];
                assign Aout4[1][4][zz]=S_out4[64*(5*4+1)+zz];
                assign Aout4[2][4][zz]=S_out4[64*(5*4+2)+zz];
                assign Aout4[3][4][zz]=S_out4[64*(5*4+3)+zz];
                assign Aout4[4][4][zz]=S_out4[64*(5*4+4)+zz];
        end
endgenerate

//A_out[0][0][z1]=Aout4[0][0][z1] ^ RC[z1];
generate
        for(genvar i0=0;i0<64;i0=i0+1)begin: Lane0_0
                assign A_out[0][0][i0]=Aout4[0][0][i0] ^ RC[i0];
        end
endgenerate

//A_out[x][y][z]=Aout4[x][y][z]
generate
        for(genvar i1=0;i1<64;i1=i1+1)begin: otherLane
                assign A_out[1][0][i1]=Aout4[1][0][i1];
                assign A_out[2][0][i1]=Aout4[2][0][i1];
                assign A_out[3][0][i1]=Aout4[3][0][i1];
                assign A_out[4][0][i1]=Aout4[4][0][i1];

                assign A_out[0][1][i1]=Aout4[0][1][i1];
                assign A_out[1][1][i1]=Aout4[1][1][i1];
                assign A_out[2][1][i1]=Aout4[2][1][i1];
                assign A_out[3][1][i1]=Aout4[3][1][i1];
                assign A_out[4][1][i1]=Aout4[4][1][i1];

                assign A_out[0][2][i1]=Aout4[0][2][i1];
                assign A_out[1][2][i1]=Aout4[1][2][i1];
                assign A_out[2][2][i1]=Aout4[2][2][i1];
                assign A_out[3][2][i1]=Aout4[3][2][i1];
                assign A_out[4][2][i1]=Aout4[4][2][i1];

                assign A_out[0][3][i1]=Aout4[0][3][i1];
                assign A_out[1][3][i1]=Aout4[1][3][i1];
                assign A_out[2][3][i1]=Aout4[2][3][i1];
                assign A_out[3][3][i1]=Aout4[3][3][i1];
                assign A_out[4][3][i1]=Aout4[4][3][i1];

                assign A_out[0][4][i1]=Aout4[0][4][i1];
                assign A_out[1][4][i1]=Aout4[1][4][i1];
                assign A_out[2][4][i1]=Aout4[2][4][i1];
                assign A_out[3][4][i1]=Aout4[3][4][i1];
                assign A_out[4][4][i1]=Aout4[4][4][i1];
        end
endgenerate

//Convert state array into str
generate
        for(genvar Z=0;Z<64;Z=Z+1)begin: arr_to_str

                assign S_out[Z] = A_out[0][0][Z]; 
                assign S_out[Z+64] = A_out[1][0][Z];
                assign S_out[Z+64*2] = A_out[2][0][Z];
                assign S_out[Z+64*3] = A_out[3][0][Z];
                assign S_out[Z+64*4] = A_out[4][0][Z];
        
                assign S_out[Z+64*5] = A_out[0][1][Z];       
                assign S_out[Z+64*6] = A_out[1][1][Z];
                assign S_out[Z+64*7] = A_out[2][1][Z];
                assign S_out[Z+64*8] = A_out[3][1][Z];
                assign S_out[Z+64*9] = A_out[4][1][Z];
        
                assign S_out[Z+64*10] = A_out[0][2][Z];
                assign S_out[Z+64*11] = A_out[1][2][Z];
                assign S_out[Z+64*12] = A_out[2][2][Z];
                assign S_out[Z+64*13] = A_out[3][2][Z];
                assign S_out[Z+64*14] = A_out[4][2][Z];
       
                assign S_out[Z+64*15] = A_out[0][3][Z];
                assign S_out[Z+64*16] = A_out[1][3][Z];
                assign S_out[Z+64*17] = A_out[2][3][Z];
                assign S_out[Z+64*18] = A_out[3][3][Z];
                assign S_out[Z+64*19] = A_out[4][3][Z];
        
                assign S_out[Z+64*20] = A_out[0][4][Z];
                assign S_out[Z+64*21] = A_out[1][4][Z];
                assign S_out[Z+64*22] = A_out[2][4][Z];
                assign S_out[Z+64*23] = A_out[3][4][Z];
                assign S_out[Z+64*24] = A_out[4][4][Z];
        end
endgenerate

endmodule