/*
    Copyright ©2020-2021 The American University in Cairo and the Cloud V Project.

    This file is part of the DFFRAM Memory Compiler.
    See https://github.com/Cloud-V/DFFRAM for further info.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
/* 
	DFFRFile
    Mohamed Shalan (mshalan@aucegypt.edu)
	32x32 Register File with 2RW1W ports and clock gating for SKY130A 
	~ 3550 Cells
	< 2ns (no input or output delays)
*/

`timescale 1ns / 1ps
`default_nettype none

module DFFRF_2R1W (
	input [4:0] 	RA, RB, RW,
	input [31:0] 	DW,
	output [31:0]	DA, DB,
	input CLK,
	input WE
);

	wire [31:0] sel1, sel2, selw;

	DEC5x32 DEC0 ( .A(RA), .SEL(sel1) );
	DEC5x32 DEC1 ( .A(RB), .SEL(sel2) );
	DEC5x32 DEC2 ( .A(RW), .SEL(selw) );
	
	RFWORD0 RFW0 ( .CLK(CLK), .WE(), .SEL1(sel1[0]), .SEL2(sel2[0]), .SELW(selw[0]), .D1(DA), .D2(DB));	

	generate
		genvar e;
        for(e=1; e<32; e=e+1) begin : FILE 
			RFWORD RFW ( .CLK(CLK), .WE(WE), .SEL1(sel1[e]), .SEL2(sel2[e]), .SELW(selw[e]), .D1(DA), .D2(DB), .DW(DW) );	
        end
	endgenerate
endmodule

module RFWORD (
    input   wire        CLK,
    input   wire        WE,
    input   wire        SEL1, 
    input   wire        SEL2, 
    input   wire        SELW,
    output  wire [31:0] D1, D2,
    input   wire [31:0] DW
);

    wire [31:0] q_wire;
    wire        we_wire;
    wire [3:0]  SEL1_B, SEL2_B;
    wire [3:0]  GCLK;

    sky130_fd_sc_hd__inv_4 INV1[3:0] (.Y(SEL1_B), .A(SEL1));
	sky130_fd_sc_hd__inv_4 INV2[3:0] (.Y(SEL2_B), .A(SEL2));

    sky130_fd_sc_hd__and2_1 CGAND ( .A(SELW), .B(WE), .X(we_wire) );
    sky130_fd_sc_hd__dlclkp_1 CG[3:0] ( .CLK(CLK), .GCLK(GCLK), .GATE(we_wire) );

    generate 
        genvar i;
        for(i=0; i<32; i=i+1) begin : BIT
            sky130_fd_sc_hd__dfxtp_1 FF ( .D(DW[i]), .Q(q_wire[i]), .CLK(GCLK[i/8]) );
            sky130_fd_sc_hd__ebufn_2 OBUF1 ( .A(q_wire[i]), .Z(D1[i]), .TE_B(SEL1_B[i/8]) );
			sky130_fd_sc_hd__ebufn_2 OBUF2 ( .A(q_wire[i]), .Z(D2[i]), .TE_B(SEL2_B[i/8]) );
        end
		
    endgenerate 
endmodule

module RFWORD0 (
    input CLK,
    input WE,
    input SEL1, SEL2, SELW,
    output [31:0] D1, D2
    //input [31:0] DW
);

    wire [31:0]  q_wire;
    wire         we_wire;
    wire [3:0]   SEL1_B, SEL2_B;
    wire [3:0]   GCLK;
	wire [7:0]	 lo;

    sky130_fd_sc_hd__inv_4 INV1[3:0] (.Y(SEL1_B), .A(SEL1));
	sky130_fd_sc_hd__inv_4 INV2[3:0] (.Y(SEL2_B), .A(SEL2));

	sky130_fd_sc_hd__conb_1 TIE [7:0] (.LO(lo), .HI());

    generate 
        genvar i;
        for(i=0; i<32; i=i+1) begin : BIT
            sky130_fd_sc_hd__ebufn_2 OBUF1 ( .A(lo[i/8]), .Z(D1[i]), .TE_B(SEL1_B[i/8]) );
			sky130_fd_sc_hd__ebufn_2 OBUF2 ( .A(lo[4+i/8]), .Z(D2[i]), .TE_B(SEL2_B[i/8]) );
        end
    endgenerate 
endmodule

module DEC2x4 (
    input           EN,
    input   [1:0]   A,
    output  [3:0]   SEL
);
    sky130_fd_sc_hd__nor3b_4    AND0 ( .Y(SEL[0]), .A(A[0]),   .B(A[1]), .C_N(EN) );
    sky130_fd_sc_hd__and3b_4    AND1 ( .X(SEL[1]), .A_N(A[1]), .B(A[0]), .C(EN) );
    sky130_fd_sc_hd__and3b_4    AND2 ( .X(SEL[2]), .A_N(A[0]), .B(A[1]), .C(EN) );
    sky130_fd_sc_hd__and3_4     AND3 ( .X(SEL[3]), .A(A[1]),   .B(A[0]), .C(EN) );
    
endmodule

module DEC3x8 (
    input   wire        EN,
    input   wire [2:0]  A,
    output  wire [7:0]  SEL
);
    sky130_fd_sc_hd__nor4b_2    AND0 ( .Y(SEL[0])  , .A(A[0]),   .B(A[1])  , .C(A[2]),   .D_N(EN) ); // 000
    sky130_fd_sc_hd__and4bb_2   AND1 ( .X(SEL[1])  , .A_N(A[2]), .B_N(A[1]), .C(A[0]),   .D(EN)   ); // 001
    sky130_fd_sc_hd__and4bb_2   AND2 ( .X(SEL[2])  , .A_N(A[2]), .B_N(A[0]), .C(A[1]),   .D(EN)   ); // 010
    sky130_fd_sc_hd__and4b_2    AND3 ( .X(SEL[3])  , .A_N(A[2]), .B(A[1])  , .C(A[0]),   .D(EN)   );   // 011
    sky130_fd_sc_hd__and4bb_2   AND4 ( .X(SEL[4])  , .A_N(A[0]), .B_N(A[1]), .C(A[2]),   .D(EN)   ); // 100
    sky130_fd_sc_hd__and4b_2    AND5 ( .X(SEL[5])  , .A_N(A[1]), .B(A[0])  , .C(A[2]),   .D(EN)   );   // 101
    sky130_fd_sc_hd__and4b_2    AND6 ( .X(SEL[6])  , .A_N(A[0]), .B(A[1])  , .C(A[2]),   .D(EN)   );   // 110
    sky130_fd_sc_hd__and4_2     AND7 ( .X(SEL[7])  , .A(A[0]),   .B(A[1])  , .C(A[2]),   .D(EN)   ); // 111
endmodule

module DEC5x32 (
    input   [4:0]   A,
    output  [31:0]   SEL
);
	wire [3:0] EN;
	DEC3x8 D0 ( .A(A[2:0]), .SEL(SEL[7:0]),   .EN(EN[0]) );
	DEC3x8 D1 ( .A(A[2:0]), .SEL(SEL[15:8]),  .EN(EN[1]) );
	DEC3x8 D2 ( .A(A[2:0]), .SEL(SEL[23:16]), .EN(EN[2]) );
	DEC3x8 D3 ( .A(A[2:0]), .SEL(SEL[31:24]), .EN(EN[3]) );

	DEC2x4 D ( .A(A[4:3]), .SEL(EN), .EN(1'b1) );
endmodule
