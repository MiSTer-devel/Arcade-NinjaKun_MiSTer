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
	input	  [7:0]	CTR3,

	input	  [7:0]	DSW1,			// DipSW
	input	  [7:0]	DSW2,
	input 	  [1:0] HWTYPE,
	
	input   [8:0]  PH,         // PIXEL H
	input   [8:0]  PV,         // PIXEL V

	output         PCLK,       // PIXEL CLOCK
	output  [7:0]  POUT,       // PIXEL OUT

	output [15:0]  SNDOUT,		// Sound Output (LPCM unsigned 16bits)


	input			ROMCL,		// Downloaded ROM image
	input  [16:0] 	ROMAD,
	input   [7:0]	ROMDT,
	input			ROMEN,

	output			CLK24M,

	input			pause,

	input	 [15:0]	hs_address,
	input	 [7:0]	hs_data_in,
	output [7:0]	hs_data_out,
	input			hs_write,
	input			hs_access
);

// Hiscore
wire [7:0]	hs_data_out_ram;
wire [7:0]	hs_data_out_vram;
wire		hs_cs_ram = (hs_address[15:13] == 3'b111);
wire		hs_cs_vram = (hs_address[15:13] == 3'b110);
assign		hs_data_out = hs_cs_ram ? hs_data_out_ram : hs_data_out_vram;

wire		VCLKx4, VCLK;
wire		VRAMCL, CLK12M, CLK6M, CLK3M;
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
wire CPSEL;

NINJAKUN_MAIN main (
	RESET, CLK24M, CLK3M, VBLK, CTR1, CTR2, CTR3, HWTYPE, CPSEL,
	CPADR, CPODT, CPIDT, CPRED, CPWRT,
	ROMCL, ROMAD, ROMDT, ROMEN,
	pause,
	
	hs_address,hs_data_in,hs_data_out_ram,hs_write & hs_cs_ram,hs_access
);

wire  [9:0] FGVAD, BGVAD;
wire [15:0] FGVDT, BGVDT;
wire [10:0] SPAAD;
wire  [7:0] SPADT;
wire  [8:0] PALET;
wire  [7:0] SCRPX, SCRPY;

NINJAKUN_IO_VIDEO iovid (
	.SHCLK(CLK24M),
	.CLK3M(CLK3M),
	.RESET(RESET),
	.VRCLK(VRAMCL),.VCLKx4(VCLKx4),.VCLK(VCLK),.PH(PH),.PV(PV),
	.CPADR(CPADR),.CPODT(CPODT),.CPIDT(CPIDT),.CPRED(CPRED),.CPWRT(CPWRT),
	.DSW1(DSW1),.DSW2(DSW2),
	.CTR1(CTR1),.CTR2(CTR2),
	.VBLK(VBLK),.POUT(POUT),.SNDOUT(SNDOUT),
	.ROMCL(ROMCL),.ROMAD(ROMAD),.ROMDT(ROMDT),.ROMEN(ROMEN),
	.HWTYPE(HWTYPE), .CPSEL(CPSEL),

	.hs_address(hs_address),
	.hs_data_in(hs_data_in),
	.hs_data_out(hs_data_out_vram),
	.hs_write(hs_write & hs_cs_vram),
	.hs_access(hs_access)
);

endmodule


module NINJAKUN_MAIN
(
	input			RESET,
	input			CLK24M,
	input			CLK3M,
	input			VBLK,

	input	  [7:0]	CTR1,
	input	  [7:0]	CTR2,
	input	  [7:0]	CTR3,
	input	  [1:0] HWTYPE,
	output 		    CPSEL,

	output [15:0]	CPADR,
	output  [7:0]	CPODT,
	input	  [7:0]	CPIDT,
	output			CPRED,
	output			CPWRT,
	
	input			ROMCL,
	input  [16:0]	ROMAD,
	input	  [7:0]	ROMDT,
	input			ROMEN,

	input			pause,

	input	 [15:0]	hs_address,
	input	 [7:0]	hs_data_in,
	output [7:0]	hs_data_out,
	input			hs_write,
	input			hs_access
);

`include "rtl/defs.v"

wire	SHCLK = CLK24M;
wire	INPCL = CLK24M;

wire	CP0IQ, CP0IQA;
wire	CP1IQ, CP1IQA;
NINJAKUN_IRQGEN irqgen( CLK3M, VBLK, CP0IQA, CP1IQA, CP0IQ, CP1IQ );

wire		CP0CL, CP1CL;
wire [15:0]	CP0AD, CP1AD;
wire  [7:0]	CP0OD, CP1OD;
wire  [7:0] CP0DT, CP1DT;
wire  [7:0]	CP0ID, CP1ID;
wire		CP0RD, CP1RD;
wire		CP0WR, CP1WR;
Z80IP cpu0( RESET, CP0CL, CP0AD, CP0DT, CP0OD, CP0RD, CP0WR, CP0IQ, CP0IQA, pause );
Z80IP cpu1( RESET, CP1CL, CP1AD, CP1DT, CP1OD, CP1RD, CP1WR, CP1IQ, CP1IQA, 1'b0 );

NINJAKUN_CPUMUX ioshare(
	SHCLK, CPADR, CPODT, CPIDT, CPRED, CPWRT, CPSEL,
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

	SYNWR0, SYNWR1, HWTYPE
);

wire [7:0] ROM0D, ROM1D;
NJC0ROM cpu0i( SHCLK, CP0AD, ROM0D, ROMCL,ROMAD,ROMDT,ROMEN );
NJC1ROM cpu1i( SHCLK, CP1AD, ROM1D, ROMCL,ROMAD,ROMDT,ROMEN );


// Hiscore mux into cpu 0 working RAM
//wire			ram_CLK = hs_access ? ROMCL : SHCLK;
wire [10:0]	ram_ADR = hs_access ? hs_address[10:0] : CP0AD[10:0];
wire			ram_WRT = hs_access ? hs_write : (CS_SH0 & CP0WR);
wire  [7:0]	ram_DIN = hs_access ? hs_data_in : CP0OD;
wire  [7:0]	ram_DOUT;
assign hs_data_out = hs_access ? ram_DOUT : 8'h00;
assign SHDT0 = hs_access ? 8'h00 : ram_DOUT;

wire RAIDERS5 = HWTYPE == `HW_RAIDERS5;

wire [7:0] SHDT0, SHDT1;
DPRAM800	shmem(
	SHCLK, ram_ADR, ram_WRT, ram_DIN, ram_DOUT,
	SHCLK, {(RAIDERS5 ^ ~CP1AD[10]),CP1AD[9:0]}, CS_SH1 & CP1WR, CP1OD, SHDT1
);

wire [7:0] INPD0, INPD1;

NINJAKUN_INP inps(
	.INPCL(INPCL),
	.RESET(RESET),
	.HWTYPE(HWTYPE),
	.CTR1i(CTR1),	// Control Panel (Negative Logic)
	.CTR2i(CTR2),
	.CTR3i(CTR3),
	.VBLK(VBLK), 
	.AD0({HWTYPE[1] ? CP0AD[3] : CP0AD[1], CP0AD[0]}),
	.OD0(CP0OD[7:6]),
	.WR0(SYNWR0),
	.AD1(CP1AD[1:0]),
	.OD1(CP1OD[7:6]),
	.WR1(SYNWR1),
	.INPD0(INPD0),
	.INPD1(INPD1)
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
	input		CLK,
	input		VBLK,

	input		IRQ0_ACK,
	input		IRQ1_ACK,

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
	output [7:0] 	out,
	input  [7:0] 	df,

	input			en0,
	input	 [7:0] 	dt0,
	input			en1,
	input	 [7:0] 	dt1,
	input			en2,
	input	 [7:0] 	dt2
);

assign out = en0 ? dt0 :
				 en1 ? dt1 :
				 en2 ? dt2 :
				 df;

endmodule

