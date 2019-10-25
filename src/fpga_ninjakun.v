/***********************************************
    "FPGA NinjaKun" for MiSTer

					Copyright (c) 2011,19 MiSTer-X
************************************************/
module FPGA_NINJAKUN
(
	input          RESET,      // RESET
	input          MCLK,       // Master Clock (48.0MHz)

	input	  [7:0]	CTR1,			// Control Panel
	input	  [7:0]	CTR2,

	input	  [7:0]	DSW1,			// DipSW
	input	  [7:0]	DSW2,
	
	input   [8:0]  PH,         // PIXEL H
	input   [8:0]  PV,         // PIXEL V

	output         PCLK,       // PIXEL CLOCK
	output  [7:0]  POUT,       // PIXEL OUT

	output [15:0]  SNDOUT,		// Sound Output (LPCM unsigned 16bits)


	input				ROMCL,		// Downloaded ROM image
	input  [16:0] 	ROMAD,
	input   [7:0]	ROMDT,
	input				ROMEN
);

wire			VCLKx4, VCLK;
wire			VRAMCL, CLK24M, CLK12M, CLK6M, CLK3M;
NINJAKUN_CLKGEN clkgen
(
	MCLK,
	VCLKx4, VCLK,
	VRAMCL, PCLK,
	CLK24M, CLK12M, CLK6M, CLK3M
);

wire [15:0] CPADR;
wire  [7:0] CPODT, CPIDT;
wire        CPRED, CPWRT, VBLK;
NINJAKUN_MAIN main (
	RESET, CLK24M, CLK3M, VBLK, CTR1, CTR2, 
	CPADR, CPODT, CPIDT, CPRED, CPWRT,
	ROMCL, ROMAD, ROMDT, ROMEN
);

wire  [9:0] FGVAD, BGVAD;
wire [15:0] FGVDT, BGVDT;
wire [10:0] SPAAD;
wire  [7:0] SPADT;
wire  [8:0] PALET;
wire  [7:0] SCRPX, SCRPY;

NINJAKUN_IO_VIDEO iovid (
   CLK24M,CLK3M,RESET,
	VRAMCL,VCLKx4,VCLK,PH,PV,
	CPADR,CPODT,CPIDT,CPRED,CPWRT,
 	DSW1,DSW2,
	VBLK,POUT,SNDOUT,
	ROMCL,ROMAD,ROMDT,ROMEN
);

endmodule


module NINJAKUN_MAIN
(
	input				RESET,
	input				CLK24M,
	input				CLK3M,
	input				VBLK,

	input	  [7:0]	CTR1,
	input	  [7:0]	CTR2,

	output [15:0]	CPADR,
	output  [7:0]	CPODT,
	input	  [7:0]	CPIDT,
	output			CPRED,
	output			CPWRT,
	
	input				ROMCL,
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input				ROMEN
);

wire	SHCLK = CLK24M;
wire	INPCL = CLK24M;

wire	CP0IQ, CP0IQA;
wire	CP1IQ, CP1IQA;
NINJAKUN_IRQGEN irqgen( CLK3M, VBLK, CP0IQA, CP1IQA, CP0IQ, CP1IQ );

wire			CP0CL, CP1CL;
wire [15:0]	CP0AD, CP1AD;
wire  [7:0]	CP0OD, CP1OD;
wire  [7:0] CP0DT, CP1DT;
wire  [7:0]	CP0ID, CP1ID;
wire			CP0RD, CP1RD;
wire			CP0WR, CP1WR;
Z80IP cpu0( RESET, CP0CL, CP0AD, CP0DT, CP0OD, CP0RD, CP0WR, CP0IQ, CP0IQA );
Z80IP cpu1( RESET, CP1CL, CP1AD, CP1DT, CP1OD, CP1RD, CP1WR, CP1IQ, CP1IQA );

NINJAKUN_CPUMUX ioshare(
	SHCLK, CPADR, CPODT, CPIDT, CPRED, CPWRT,
	CP0CL, CP0AD, CP0OD, CP0ID, CP0RD, CP0WR,
	CP1CL, CP1AD, CP1OD, CP1ID, CP1RD, CP1WR
);

wire CS_SH0, CS_SH1, CS_IN0, CS_IN1;
wire SYNWR0, SYNWR1;
NINJAKUN_ADEC adec(
	CP0AD, CP0WR,
	CP1AD, CP1WR,

	CS_IN0, CS_IN1,
	CS_SH0, CS_SH1,

	SYNWR0, SYNWR1
);


wire [7:0] ROM0D, ROM1D;
NJC0ROM cpu0i( SHCLK, CP0AD, ROM0D, ROMCL,ROMAD,ROMDT,ROMEN );
NJC1ROM cpu1i( SHCLK, CP1AD, ROM1D, ROMCL,ROMAD,ROMDT,ROMEN );


wire [7:0] SHDT0, SHDT1;
DPRAM800	shmem(
	SHCLK, {  CP0AD[10] ,CP0AD[9:0]}, CS_SH0 & CP0WR, CP0OD, SHDT0,
	SHCLK, {(~CP1AD[10]),CP1AD[9:0]}, CS_SH1 & CP1WR, CP1OD, SHDT1
);

wire [7:0] INPD0, INPD1;
NINJAKUN_INP inps(
	INPCL,
	RESET,

	CTR1,CTR2,

	VBLK, 

	CP0AD[1:0],
	CP0OD[7:6],
	SYNWR0,

	CP1AD[1:0],
	CP1OD[7:6],
	SYNWR1,

	INPD0,
	INPD1
);

DSEL3D_8B cdt0(
	CP0DT,  CP0ID,
	CS_IN0, INPD0,
	CS_SH0, SHDT0,
	(~CP0AD[15]), ROM0D
);

DSEL3D_8B cdt1(
	CP1DT,  CP1ID,
	CS_IN1, INPD1,
	CS_SH1, SHDT1,
	(~CP1AD[15]), ROM1D
);

endmodule


module NINJAKUN_IRQGEN
( 
	input			CLK,
	input			VBLK,

	input			IRQ0_ACK,
	input			IRQ1_ACK,

	output reg	IRQ0,
	output reg	IRQ1
);

`define CYCLES 12500		// 1/240sec.

reg  pVBLK;
wire VBTG = VBLK & (pVBLK^VBLK);

reg [13:0] cnt;
wire IRQ1_ACT = (cnt == 1);
wire CNTR_RST = (cnt == `CYCLES)|VBTG;

always @( posedge CLK ) begin
	if (VBTG)	  IRQ0 <= 1'b1;
	if (IRQ1_ACT) IRQ1 <= 1'b1;

	if (IRQ0_ACK) IRQ0 <= 1'b0;
	if (IRQ1_ACK) IRQ1 <= 1'b0;

	cnt   <= CNTR_RST ? 0 : (cnt+1);
	pVBLK <= VBLK;
end

endmodule 


module DSEL3D_8B
(
	output [7:0] out,
	input  [7:0] df,

	input			 en0,
	input	 [7:0] dt0,
	input			 en1,
	input	 [7:0] dt1,
	input			 en2,
	input	 [7:0] dt2
);

assign out = en0 ? dt0 :
				 en1 ? dt1 :
				 en2 ? dt2 :
				 df;

endmodule

