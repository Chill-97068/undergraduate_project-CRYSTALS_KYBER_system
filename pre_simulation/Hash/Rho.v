module Rho(input [0:1599]S,output  [0:1599]S_out);

wire A[0:4][0:4][0:63];
wire A_out[0:4][0:4][0:63];



//str to state array(A[x][y][z]=S[64*(5*y+x)+z])
generate
        for(genvar zz=0;zz<64;zz=zz+1)begin: str_to_arr
                assign A[0][0][zz]=S[64*(5*0+0)+zz];
                assign A[1][0][zz]=S[64*(5*0+1)+zz];
                assign A[2][0][zz]=S[64*(5*0+2)+zz];
                assign A[3][0][zz]=S[64*(5*0+3)+zz];
                assign A[4][0][zz]=S[64*(5*0+4)+zz];

                assign A[0][1][zz]=S[64*(5*1+0)+zz];
                assign A[1][1][zz]=S[64*(5*1+1)+zz];
                assign A[2][1][zz]=S[64*(5*1+2)+zz];
                assign A[3][1][zz]=S[64*(5*1+3)+zz];
                assign A[4][1][zz]=S[64*(5*1+4)+zz];

                assign A[0][2][zz]=S[64*(5*2+0)+zz];
                assign A[1][2][zz]=S[64*(5*2+1)+zz];
                assign A[2][2][zz]=S[64*(5*2+2)+zz];
                assign A[3][2][zz]=S[64*(5*2+3)+zz];
                assign A[4][2][zz]=S[64*(5*2+4)+zz];

                assign A[0][3][zz]=S[64*(5*3+0)+zz];
                assign A[1][3][zz]=S[64*(5*3+1)+zz];
                assign A[2][3][zz]=S[64*(5*3+2)+zz];
                assign A[3][3][zz]=S[64*(5*3+3)+zz];
                assign A[4][3][zz]=S[64*(5*3+4)+zz];

                assign A[0][4][zz]=S[64*(5*4+0)+zz];
                assign A[1][4][zz]=S[64*(5*4+1)+zz];
                assign A[2][4][zz]=S[64*(5*4+2)+zz];
                assign A[3][4][zz]=S[64*(5*4+3)+zz];
                assign A[4][4][zz]=S[64*(5*4+4)+zz];
        end
endgenerate



generate
        for(genvar z=0;z<64;z=z+1)begin: Lane00
                assign A_out[0][0][z] = A[0][0][z];
        end
endgenerate

/*
x=1,y=0
for t=0~23 begin
A_out[x][y][z] = A[x][y][(z-(t+1)*(t+2)/2) % 64]
(x,y)=(y,(2x+3y)%5)
end
*/

//t=0
assign A_out[1][0][0] = A[1][0][63];
generate
        for(genvar i=1;i<64;i=i+1)begin: t0
                assign A_out[1][0][i] = A[1][0][(i-(0+1)*(0+2)/2) % 64];
        end
endgenerate

//t=1
assign A_out[0][2][0] = A[0][2][61];
assign A_out[0][2][1] = A[0][2][62];
assign A_out[0][2][2] = A[0][2][63];
generate
        for(genvar i1=3;i1<64;i1=i1+1)begin: t1
                assign A_out[0][2][i1] = A[0][2][(i1-(1+1)*(1+2)/2) % 64];
        end
endgenerate

//t=2
assign A_out[2][1][0] = A[2][1][58];
assign A_out[2][1][1] = A[2][1][59];
assign A_out[2][1][2] = A[2][1][60];
assign A_out[2][1][3] = A[2][1][61];
assign A_out[2][1][4] = A[2][1][62];
assign A_out[2][1][5] = A[2][1][63];
generate
        for(genvar i2=6;i2<64;i2=i2+1)begin: t2
                assign A_out[2][1][i2] = A[2][1][(i2-(2+1)*(2+2)/2) % 64];
        end
endgenerate

//t=3
generate
        for(genvar ii3=0;ii3<10;ii3=ii3+1)begin: t3_1
                assign A_out[1][2][ii3] = A[1][2][54+ii3];
        end
endgenerate
generate
        for(genvar i3=10;i3<64;i3=i3+1)begin: t3_2
                assign A_out[1][2][i3] = A[1][2][(i3-(3+1)*(3+2)/2) % 64];
        end
endgenerate

//t=4
generate
        for(genvar ii4=0;ii4<15;ii4=ii4+1)begin: t4_1
                assign A_out[2][3][ii4] = A[2][3][49+ii4];
        end
endgenerate
generate
        for(genvar i4=15;i4<64;i4=i4+1)begin: t4_2
                assign A_out[2][3][i4] = A[2][3][(i4-(4+1)*(4+2)/2) % 64];
        end
endgenerate

//t=5
generate
        for(genvar ii5=0;ii5<21;ii5=ii5+1)begin: t5_1
                assign A_out[3][3][ii5] = A[3][3][43+ii5];
        end
endgenerate
generate
        for(genvar i5=21;i5<64;i5=i5+1)begin: t5_2
                assign A_out[3][3][i5] = A[3][3][(i5-(5+1)*(5+2)/2) % 64];
        end
endgenerate

//t=6
generate
        for(genvar ii6=0;ii6<28;ii6=ii6+1)begin: t6_1
                assign A_out[3][0][ii6] = A[3][0][36+ii6];
        end
endgenerate
generate
        for(genvar i6=28;i6<64;i6=i6+1)begin: t6_2
                assign A_out[3][0][i6] = A[3][0][(i6-(6+1)*(6+2)/2) % 64];
        end
endgenerate

//t=7
generate
        for(genvar ii7=0;ii7<36;ii7=ii7+1)begin: t7_1
                assign A_out[0][1][ii7] = A[0][1][28+ii7];
        end
endgenerate
generate
        for(genvar i7=36;i7<64;i7=i7+1)begin: t7_2
                assign A_out[0][1][i7] = A[0][1][(i7-(7+1)*(7+2)/2) % 64];
        end
endgenerate

//t=8
generate
        for(genvar ii8=0;ii8<45;ii8=ii8+1)begin: t8_1
                assign A_out[1][3][ii8] = A[1][3][19+ii8];
        end
endgenerate
generate
        for(genvar i8=45;i8<64;i8=i8+1)begin: t8_2
                assign A_out[1][3][i8] = A[1][3][(i8-(8+1)*(8+2)/2) % 64];
        end
endgenerate

//t=9
generate
        for(genvar ii9=0;ii9<55;ii9=ii9+1)begin: t9_1
                assign A_out[3][1][ii9] = A[3][1][9+ii9];
        end
endgenerate
generate
        for(genvar i9=55;i9<64;i9=i9+1)begin: t9_2
                assign A_out[3][1][i9] = A[3][1][(i9-(9+1)*(9+2)/2) % 64];
        end
endgenerate

//t=10
assign A_out[1][4][0] = A[1][4][62];
assign A_out[1][4][1] = A[1][4][63];
generate
        for(genvar i10=2;i10<64;i10=i10+1)begin: t10
                assign A_out[1][4][i10] = A[1][4][i10-2];
        end
endgenerate

//t=11
generate
        for(genvar ii11=0;ii11<14;ii11=ii11+1)begin: t11_1
                assign A_out[4][4][ii11] = A[4][4][50+ii11];
        end
endgenerate
generate
        for(genvar i11=14;i11<64;i11=i11+1)begin: t11_2
                assign A_out[4][4][i11] = A[4][4][i11-14];
        end
endgenerate

//t=12
generate
        for(genvar ii12=0;ii12<27;ii12=ii12+1)begin: t12_1
                assign A_out[4][0][ii12] = A[4][0][37+ii12];
        end
endgenerate
generate
        for(genvar i12=27;i12<64;i12=i12+1)begin: t12_2
                assign A_out[4][0][i12] = A[4][0][i12-27];
        end
endgenerate

//t=13
generate
        for(genvar ii13=0;ii13<41;ii13=ii13+1)begin: t13_1
                assign A_out[0][3][ii13] = A[0][3][23+ii13];
        end
endgenerate
generate
        for(genvar i13=41;i13<64;i13=i13+1)begin: t13_2
                assign A_out[0][3][i13] = A[0][3][i13-41];
        end
endgenerate

//t=14
generate
        for(genvar ii14=0;ii14<56;ii14=ii14+1)begin: t14_1
                assign A_out[3][4][ii14] = A[3][4][8+ii14];
        end
endgenerate
generate
        for(genvar i14=56;i14<64;i14=i14+1)begin: t14_2
                assign A_out[3][4][i14] = A[3][4][i14-56];
        end
endgenerate

//t=15
generate
        for(genvar ii15=0;ii15<8;ii15=ii15+1)begin: t15_1
                assign A_out[4][3][ii15] = A[4][3][56+ii15];
        end
endgenerate
generate
        for(genvar i15=8;i15<64;i15=i15+1)begin: t15_2
                assign A_out[4][3][i15] = A[4][3][i15-8];
        end
endgenerate

//t=16
generate
        for(genvar ii16=0;ii16<25;ii16=ii16+1)begin: t16_1
                assign A_out[3][2][ii16] = A[3][2][39+ii16];
        end
endgenerate
generate
        for(genvar i16=25;i16<64;i16=i16+1)begin: t16_2
                assign A_out[3][2][i16] = A[3][2][i16-25];
        end
endgenerate

//t=17
generate
        for(genvar ii17=0;ii17<43;ii17=ii17+1)begin: t17_1
                assign A_out[2][2][ii17] = A[2][2][21+ii17];
        end
endgenerate
generate
        for(genvar i17=43;i17<64;i17=i17+1)begin: t17_2
                assign A_out[2][2][i17] = A[2][2][i17-43];
        end
endgenerate

//t=18
generate
        for(genvar ii18=0;ii18<62;ii18=ii18+1)begin: t18_1
                assign A_out[2][0][ii18] = A[2][0][2+ii18];
        end
endgenerate
generate
        for(genvar i18=62;i18<64;i18=i18+1)begin: t18_2
                assign A_out[2][0][i18] = A[2][0][i18-62];
        end
endgenerate

//t=19
generate
        for(genvar ii19=0;ii19<18;ii19=ii19+1)begin: t19_1
                assign A_out[0][4][ii19] = A[0][4][46+ii19];
        end
endgenerate
generate
        for(genvar i19=18;i19<64;i19=i19+1)begin: t19_2
                assign A_out[0][4][i19] = A[0][4][i19-18];
        end
endgenerate

//t=20
generate
        for(genvar ii20=0;ii20<39;ii20=ii20+1)begin: t20_1
                assign A_out[4][2][ii20] = A[4][2][25+ii20];
        end
endgenerate
generate
        for(genvar i20=39;i20<64;i20=i20+1)begin: t20_2
                assign A_out[4][2][i20] = A[4][2][i20-39];
        end
endgenerate

//t=21
generate
        for(genvar ii21=0;ii21<61;ii21=ii21+1)begin: t21_1
                assign  A_out[2][4][ii21] = A[2][4][3+ii21];
        end
endgenerate
generate
        for(genvar i21=61;i21<64;i21=i21+1)begin: t21_2
                assign  A_out[2][4][i21] = A[2][4][i21-61];
        end
endgenerate

//t=22
generate
        for(genvar ii22=0;ii22<20;ii22=ii22+1)begin: t22_1
                assign  A_out[4][1][ii22] = A[4][1][44+ii22];
        end
endgenerate
generate
        for(genvar i22=20;i22<64;i22=i22+1)begin: t22_2
                assign  A_out[4][1][i22] = A[4][1][i22-20];
        end
endgenerate

//t=23
generate
        for(genvar ii23=0;ii23<44;ii23=ii23+1)begin: t23_1
                assign  A_out[1][1][ii23] = A[1][1][20+ii23];
        end
endgenerate
generate
        for(genvar i23=44;i23<64;i23=i23+1)begin: t23_2
                assign  A_out[1][1][i23] = A[1][1][i23-44];
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