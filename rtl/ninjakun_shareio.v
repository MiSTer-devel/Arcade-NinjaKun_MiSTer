// Copyright (c) 2011,19 MiSTer-X

module NINJAKUN_IO_VIDEO
(
	input				SHCLK,
	input				CLK3M,
	input				RESET,

	input				VRCLK,
	input				VCLKx4,
	input				VCLK,
	input	  [8:0]	PH,
	input	  [8:0]	PV,

	input  [15:0]	CPADR,
	input   [7:0]	CPODT,
	output  [7:0]	CPIDT,
	input    		CPRED,
	input    		CPWRT,

	input   [7:0]  DSW1,
	input   [7:0]  DSW2,

	input   [7:0]  CTR1,
	input   [7:0]  CTR2,


	output			VBLK,
	output  [7:0]	POUT,

	output [15:0]	SNDOUT,
	
	input			ROMCL,
	input  [16:0]	ROMAD,
	input   [7:0]	ROMDT,
	input			ROMEN,
	input   [1:0]	HWTYPE,
	input   CPSEL,
	input   [4:0] PALADR,
	input         PALWR,
	input   [7:0] PALDAT,

	input			pause,

	input	 [15:0]	hs_address,
	input	 [7:0]	hs_data_in,
	output [7:0]	hs_data_out,
	input			hs_write,
	input			hs_access
);
`include "rtl/defs.v"

wire  [9:0]	FGVAD;
wire [15:0]	FGVDT;
wire  [9:0]	BGVAD;
wire [15:0]	BGVDT;
wire [10:0]	SPAAD;
wire  [7:0]	SPADT;

wire  RAIDERS5 = HWTYPE == `HW_RAIDERS5;
wire  [7:0]	SCRPX = RAIDERS5 ? SCRPX_CPU : SCRPX_PSG, SCRPY = RAIDERS5 ? SCRPY_CPU : SCRPY_PSG;
wire  [7:0]	SCRPX_PSG, SCRPY_PSG;
reg   [7:0] SCRPX_CPU, SCRPY_CPU;

wire  [8:0]	PALET;

NINJAKUN_VIDEO video (
	RESET, VCLKx4, VCLK, PH, PV,
	PALET,
	FGVAD, FGVDT,
	BGVAD, BGVDT, SCRPX, SCRPY,
	SPAAD, SPADT,
	VBLK, 1'b0,

	ROMCL,ROMAD,ROMDT,ROMEN,HWTYPE
);

wire CS_PSG, CS_FGV, CS_BGV, CS_SPA, CS_PAL,CS_SCRX, CS_SCRY;
NINJAKUN_SADEC sadec( CPADR, CS_PSG, CS_FGV, CS_BGV, CS_SPA, CS_PAL, CS_SCRX, CS_SCRY, HWTYPE, CPSEL );

wire  [9:0] BGOFS =  CPADR[9:0]+{SCRPY[7:3],SCRPX[7:3]};
wire [10:0] BGADR = HWTYPE[1] ? CPADR[10:0] : {CPADR[10],BGOFS};

wire  [7:0] PSDAT, FGDAT, BGDAT, SPDAT, PLDAT;

// Hiscore mux into foreground video RAM
wire		fgv_CLK = hs_access ? ROMCL : SHCLK;
wire [10:0]	fgv_ADR = hs_access ? hs_address[10:0] : CPADR[10:0];
wire		fgv_WRT = hs_access ? hs_write : (CS_FGV & CPWRT);
wire  [7:0]	fgv_DIN = hs_access ? hs_data_in : CPODT;
wire  [7:0]	fgv_DOUT;
assign hs_data_out = hs_access ? fgv_DOUT : 8'h00;
assign FGDAT = hs_access ? 8'h00 : fgv_DOUT;

VDPRAM400x2	fgv( fgv_CLK, fgv_ADR, fgv_WRT, fgv_DIN, fgv_DOUT, VRCLK, FGVAD, FGVDT );
VDPRAM400x2	bgv( SHCLK, BGADR      , CS_BGV & CPWRT, CPODT, BGDAT, VRCLK, BGVAD, BGVDT );
DPRAM800		spa( SHCLK, CPADR[10:0], CS_SPA & CPWRT, CPODT, SPDAT, VRCLK, SPAAD, 1'b0, 8'h0, SPADT );
DPRAM200		pal( SHCLK, CPADR[ 8:0], CS_PAL & CPWRT, CPODT, PLDAT,  VCLK, PALWR ? PALADR : PALET, PALWR, PALDAT, POUT  );

DSEL5_8B cpxdsel(
	CPIDT,
	CS_PSG, PSDAT,
	CS_FGV, FGDAT,
	CS_BGV, BGDAT,
	CS_SPA, SPDAT,
	CS_PAL, PLDAT
);

NINJAKUN_PSG psg(
	SHCLK, CLK3M, CPADR[1:0], CS_PSG, CPWRT, CPODT, PSDAT, RESET, CPRED,
	DSW1, DSW2, SCRPX_PSG, SCRPY_PSG,
	SNDOUT, HWTYPE, CTR1, CTR2, VBLK
);

always @(posedge SHCLK) begin
	if (RESET) begin
		SCRPX_CPU <= 0;
		SCRPY_CPU <= 0;
	end else begin
		if (CS_SCRX) SCRPX_CPU <= CPODT;
		if (CS_SCRY) SCRPY_CPU <= CPODT;
	end
end

endmodule


module NINJAKUN_CPUMUX
(
	input				SHCLK,
	output [15:0]	CPADR,
	output  [7:0]	CPODT,
	input   [7:0]	CPIDT,
	output    		CPRED,
	output    		CPWRT,
	output          CPSEL,

	output reg		CP0CL,
	input  [15:0]	CP0AD,
	input   [7:0]	CP0OD,
	output  [7:0]	CP0ID,
	input    		CP0RD,
	input    		CP0WR,

	output reg		CP1CL,
	input  [15:0]	CP1AD,
	input   [7:0]	CP1OD,
	output  [7:0]	CP1ID,
	input    		CP1RD,
	input    		CP1WR
);
assign     CPSEL = CSIDE;

reg  [7:0] CP0DT, CP1DT;
reg  [2:0] PHASE;
reg		  CSIDE;
always @( posedge SHCLK ) begin	// 24MHz
	case (PHASE)
	0: begin CP0DT <= CPIDT; CSIDE <= 1'b0; end
	4: begin CP1DT <= CPIDT; CSIDE <= 1'b1; end
	default:;
	endcase
end
always @( negedge SHCLK ) begin
	case (PHASE)
	0: CP0CL <= 1'b1;
	2: CP0CL <= 1'b0;
	4: CP1CL <= 1'b1;
	6: CP1CL <= 1'b0;
	default:;
	endcase
	PHASE <= PHASE+1;
end

assign CPADR = CSIDE ? CP1AD : CP0AD;
assign CPODT = CSIDE ? CP1OD : CP0OD;
assign CPRED = CSIDE ? CP1RD : CP0RD;
assign CPWRT = CSIDE ? CP1WR : CP0WR;
assign CP0ID = CSIDE ? CP0DT : CPIDT;
assign CP1ID = CSIDE ? CPIDT : CP1DT;

endmodule


module NINJAKUN_PSG
(
	input			AXSCLK,
	input			CLK,
	input	 [1:0]	ADR,
	input			CS,
	input			WR,
	input	 [7:0]	ID,
	output   [7:0]	OD,

	input			RESET,
	input			RD,

	input	 [7:0]	DSW1,
	input	 [7:0]	DSW2,

	output [7:0]	SCRPX_PSG,
	output [7:0]	SCRPY_PSG,

	output [15:0]	SNDO,
	input [1:0]	 	HWTYPE,
	input [7:0] 	CTR1,
	input [7:0] 	CTR2,
	input VBLK
);
`include "rtl/defs.v"

wire [7:0] OD0, OD1;
assign OD = psg1cs ? OD1 : OD0;

reg [7:0] SA0, SB0, SC0; wire [7:0] S0x; wire [1:0] S0c;
reg [7:0] SA1, SB1, SC1; wire [7:0] S1x; wire [1:0] S1c;

reg [1:0] encnt;
reg ENA;
always @(posedge AXSCLK) begin
	ENA <= (encnt==0);
	encnt <= encnt+1'd1;
	case (HWTYPE)
	`HW_NINJAKUN, `HW_RAIDERS5:
		if (encnt == 7) encnt <= 0; // 6 MHz
	`HW_NOVA2001:
		if (encnt == 11) encnt <= 0; // 4 MHz
	default: ; // 3 MHz
	endcase

	case (S0c)
	2'd0: SA0 <= S0x;
	2'd1: SB0 <= S0x;
	2'd2: SC0 <= S0x;
	default:;
	endcase
	case (S1c)
	2'd0: SA1 <= S1x;
	2'd1: SB1 <= S1x;
	2'd2: SC1 <= S1x;
	default:;
	endcase
end

wire psgxad = HWTYPE == `HW_NOVA2001 ? ADR[1] : ~ADR[0];
wire psg0cs = CS & (HWTYPE == `HW_NOVA2001 ? ~ADR[0] : ~ADR[1]);
wire psg0bd = psg0cs & (WR|psgxad);
wire psg0bc = psg0cs & ((~WR)|psgxad);

wire psg1cs = CS & (HWTYPE == `HW_NOVA2001 ? ADR[0] : ADR[1]);
wire psg1bd = psg1cs & (WR|psgxad);
wire psg1bc = psg1cs & ((~WR)|psgxad);

wire [7:0] IOA_PSG0, IOB_PSG0;
wire [7:0] IOA_PSG1, IOB_PSG1;
assign SCRPX_PSG = HWTYPE == `HW_NOVA2001 ? IOA_PSG0 : IOA_PSG1;
assign SCRPY_PSG = HWTYPE == `HW_NOVA2001 ? IOB_PSG0 : IOB_PSG1;

wire IO_TYPE = HWTYPE == `HW_RAIDERS5 || HWTYPE == `HW_PKUNWAR;

YM2149 psg0(
	.I_DA(ID),
	.O_DA(OD0),
	.I_A9_L(~psg0cs),
	.I_BDIR(psg0bd),
	.I_BC1(psg0bc),
	.I_A8(1'b1),
	.I_BC2(1'b1),
	.I_SEL_L(1'b0),
	.O_AUDIO(S0x),
	.O_CHAN(S0c),
	.I_IOA(IO_TYPE ? {~VBLK, CTR1[6:0]} : DSW1),
	.I_IOB(IO_TYPE ? CTR2 : DSW2),
	.O_IOA(IOA_PSG0),
	.O_IOB(IOB_PSG0),
	.ENA(ENA),
	.RESET_L(~RESET),
	.CLK(AXSCLK)
);

YM2149 psg1(
	.I_DA(ID),
	.O_DA(OD1),
	.I_A9_L(~psg1cs),
	.I_BDIR(psg1bd),
	.I_BC1(psg1bc),
	.I_A8(1'b1),
	.I_BC2(1'b1),
	.I_SEL_L(1'b0),
	.O_AUDIO(S1x),
	.O_CHAN(S1c),
	.I_IOA(HWTYPE == `HW_NINJAKUN ? 8'd0 : DSW1),
	.I_IOB(HWTYPE == `HW_NINJAKUN ? 8'd0 : DSW2),
	.O_IOA(IOA_PSG1),
	.O_IOB(IOB_PSG1),
	.ENA(ENA),
	.RESET_L(~RESET),
	.CLK(AXSCLK)
);

wire [11:0] SND = SA0+SB0+SC0+SA1+SB1+SC1;
assign SNDO = {SND,SND[3:0]};

endmodule


module DSEL5_8B
(
	output [7:0] out,

	input			 en0,
	input  [7:0] dt0,
	
	input			 en1,
	input  [7:0] dt1,

	input			 en2,
	input  [7:0] dt2,

	input			 en3,
	input  [7:0] dt3,

	input			 en4,
	input  [7:0] dt4
);

assign out = en0 ? dt0 :
				 en1 ? dt1 :
				 en2 ? dt2 :
				 en3 ? dt3 :
				 en4 ? dt4 :
				 8'hFF;

endmodule

