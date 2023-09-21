module Pi(input [0:1599]S,output  [0:1599]S_out);

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

//A_out[x][y][z]=A[(x+3*y)%5][x][z];
generate
        for(genvar i=0;i<64;i=i+1)begin: Lane00
                assign A_out[0][0][i]=A[(0+3*0)%5][0][i];
        end
endgenerate
generate
        for(genvar i1=0;i1<64;i1=i1+1)begin: Lane10
                assign A_out[1][0][i1]=A[(1+3*0)%5][1][i1];
        end
endgenerate
generate
        for(genvar i2=0;i2<64;i2=i2+1)begin: Lane20
                assign A_out[2][0][i2]=A[(2+3*0)%5][2][i2];
        end
endgenerate
generate
        for(genvar i3=0;i3<64;i3=i3+1)begin: Lane30
                assign A_out[3][0][i3]=A[(3+3*0)%5][3][i3];
        end
endgenerate
generate
        for(genvar i4=0;i4<64;i4=i4+1)begin: Lane40
                assign A_out[4][0][i4]=A[(4+3*0)%5][4][i4];
        end
endgenerate
generate
        for(genvar i5=0;i5<64;i5=i5+1)begin: Lane01
                assign A_out[0][1][i5]=A[(0+3*1)%5][0][i5];
        end
endgenerate
generate
        for(genvar i6=0;i6<64;i6=i6+1)begin: Lane11
                assign A_out[1][1][i6]=A[(1+3*1)%5][1][i6];
        end
endgenerate
generate
        for(genvar i7=0;i7<64;i7=i7+1)begin: Lane21
                assign A_out[2][1][i7]=A[(2+3*1)%5][2][i7];
        end
endgenerate
generate
        for(genvar i8=0;i8<64;i8=i8+1)begin: Lane31
                assign A_out[3][1][i8]=A[(3+3*1)%5][3][i8];
        end
endgenerate
generate
        for(genvar i9=0;i9<64;i9=i9+1)begin: Lane41
                assign A_out[4][1][i9]=A[(4+3*1)%5][4][i9];
        end
endgenerate
generate
        for(genvar i10=0;i10<64;i10=i10+1)begin: Lane02
                assign A_out[0][2][i10]=A[(0+3*2)%5][0][i10];
        end
endgenerate
generate
        for(genvar i11=0;i11<64;i11=i11+1)begin: Lane12
                assign A_out[1][2][i11]=A[(1+3*2)%5][1][i11];
        end
endgenerate
generate
        for(genvar i12=0;i12<64;i12=i12+1)begin: Lane22
                assign A_out[2][2][i12]=A[(2+3*2)%5][2][i12];
        end
endgenerate
generate
        for(genvar i13=0;i13<64;i13=i13+1)begin: Lane32
                assign A_out[3][2][i13]=A[(3+3*2)%5][3][i13];
        end
endgenerate
generate
        for(genvar i14=0;i14<64;i14=i14+1)begin: Lane42
                assign A_out[4][2][i14]=A[(4+3*2)%5][4][i14];
        end
endgenerate
generate
        for(genvar i15=0;i15<64;i15=i15+1)begin: Lane03
                assign A_out[0][3][i15]=A[(0+3*3)%5][0][i15];
        end
endgenerate
generate
        for(genvar i16=0;i16<64;i16=i16+1)begin: Lane13
                assign A_out[1][3][i16]=A[(1+3*3)%5][1][i16];
        end
endgenerate
generate
        for(genvar i17=0;i17<64;i17=i17+1)begin: Lane23
                assign A_out[2][3][i17]=A[(2+3*3)%5][2][i17];
        end
endgenerate
generate
        for(genvar i18=0;i18<64;i18=i18+1)begin: Lane33
                assign A_out[3][3][i18]=A[(3+3*3)%5][3][i18];
        end
endgenerate
generate
        for(genvar i19=0;i19<64;i19=i19+1)begin: Lane43
                assign A_out[4][3][i19]=A[(4+3*3)%5][4][i19];
        end
endgenerate
generate
        for(genvar i20=0;i20<64;i20=i20+1)begin: Lane04
                assign A_out[0][4][i20]=A[(0+3*4)%5][0][i20];
        end
endgenerate
generate
        for(genvar i21=0;i21<64;i21=i21+1)begin: Lane14
                assign A_out[1][4][i21]=A[(1+3*4)%5][1][i21];
        end
endgenerate
generate
        for(genvar i22=0;i22<64;i22=i22+1)begin: Lane24
                assign A_out[2][4][i22]=A[(2+3*4)%5][2][i22];
        end
endgenerate
generate
        for(genvar i23=0;i23<64;i23=i23+1)begin: Lane34
                assign A_out[3][4][i23]=A[(3+3*4)%5][3][i23];
        end
endgenerate
generate
        for(genvar i24=0;i24<64;i24=i24+1)begin: Lane44
                assign A_out[4][4][i24]=A[(4+3*4)%5][4][i24];
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