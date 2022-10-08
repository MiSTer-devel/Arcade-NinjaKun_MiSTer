// Copyright (c) 2011 MiSTer-X

module NINJAKUN_SADEC
(
	input [15:0] CPADR,

	output		 CS_PSG,
	output		 CS_FGV,
	output		 CS_BGV,
	output		 CS_SPA,
	output		 CS_PAL,
	output 	     CS_SCRX,
	output 	     CS_SCRY,
	input [1:0]  HWTYPE,
	input CPSEL
);

`include "rtl/defs.v"

reg CS_PSG_1,CS_FGV_1, CS_BGV_1, CS_SPA_1, CS_PAL_1, CS_SCRX_1, CS_SCRY_1;

assign CS_PSG = CS_PSG_1;
assign CS_FGV = CS_FGV_1;
assign CS_BGV = CS_BGV_1;
assign CS_SPA = CS_SPA_1;
assign CS_PAL = CS_PAL_1;
assign CS_SCRX = CS_SCRX_1;
assign CS_SCRY = CS_SCRY_1;

always @(*) begin
	CS_PSG_1 = ( CPADR[15: 2] == 14'b1000_0000_0000_00 );
	CS_FGV_1 = ( CPADR[15:11] ==  5'b1100_0 );
	CS_BGV_1 = ( CPADR[15:11] ==  5'b1100_1 );
	CS_SPA_1 = ( CPADR[15:11] ==  5'b1101_0 );
	CS_PAL_1 = ( CPADR[15:11] ==  5'b1101_1 );
	CS_SCRX_1 = 0;
	CS_SCRY_1 = 0;

	if (HWTYPE == `HW_RAIDERS5) begin
		if (CPSEL) begin
			CS_SCRX_1 = ( CPADR == 16'he000 );
			CS_SCRY_1 = ( CPADR == 16'he001 );
			CS_PSG_1 = ( CPADR[15: 2] == 14'b1000_0000_0000_00 );
			CS_FGV_1 = 0;
			CS_BGV_1 = 0;
			CS_SPA_1 = 0;
			CS_PAL_1 = 0;
		end else begin
			CS_SCRX_1 = ( CPADR == 16'ha000 );
			CS_SCRY_1 = ( CPADR == 16'ha001 );
			CS_PSG_1 = ( CPADR[15: 2] == 14'b1100_0000_0000_00 );
			CS_FGV_1 = ( CPADR[15:11] ==  5'b1000_1 );
			CS_BGV_1 = ( CPADR[15:11] ==  5'b1001_0 );
			CS_SPA_1 = ( CPADR[15:11] ==  5'b1000_0 );
			CS_PAL_1 = ( CPADR[15:11] ==  5'b1101_0 );
		end
	end else if (HWTYPE == `HW_NOVA2001) begin
		CS_SCRX_1 = 0;
		CS_SCRY_1 = 0;
		CS_PAL_1 = 0;
		if (CPSEL) begin
			CS_PSG_1 = 0;
			CS_FGV_1 = 0;
			CS_BGV_1 = 0;
			CS_SPA_1 = 0;
		end else begin
			CS_PSG_1 = ( CPADR[15: 2] == 14'b1100_0000_0000_00 );
			CS_FGV_1 = ( CPADR[15:11] ==  5'b1010_0 );
			CS_BGV_1 = ( CPADR[15:11] ==  5'b1010_1 );
			CS_SPA_1 = ( CPADR[15:11] ==  5'b1011_0 );
		end
	end else if (HWTYPE == `HW_PKUNWAR) begin
		CS_SCRX_1 = 0;
		CS_SCRY_1 = 0;
		CS_PAL_1 = 0;
		CS_FGV_1 = 0;
		if (CPSEL) begin
			CS_PSG_1 = 0;
			CS_BGV_1 = 0;
			CS_SPA_1 = 0;
		end else begin
			CS_PSG_1 = ( CPADR[15: 2] == 14'b1010_0000_0000_00 );
			CS_BGV_1 = ( CPADR[15:11] ==  5'b1000_1 );
			CS_SPA_1 = ( CPADR[15:11] ==  5'b1000_0 );
		end
	end
end

endmodule


module NINJAKUN_ADEC
(
	input [15:0] CP0AD,
	input		 CP0WR,

	input [15:0] CP1AD,
	input		 CP1WR,

	output		 CS_IN0,
	output		 CS_IN1,

	output		 CS_SH0,
	output		 CS_SH1,

	output		 SYNWR0,
	output		 SYNWR1,
	input    [1:0] HWTYPE
);

`include "rtl/defs.v"

assign CS_IN0 = CS_IN0_1;
assign CS_IN1 = CS_IN1_1;
assign CS_SH0 = CS_SH0_1;
assign CS_SH1 = CS_SH1_1;
assign SYNWR0 = SYNWR0_1;
assign SYNWR1 = SYNWR1_1;
reg CS_IN0_1, CS_IN1_1, CS_SH0_1, CS_SH1_1, SYNWR0_1, SYNWR1_1;

always @(*) begin
	CS_IN0_1 = (CP0AD[15:2] == 14'b1010_0000_0000_00);
	CS_IN1_1 = (CP1AD[15:2] == 14'b1010_0000_0000_00);

	CS_SH0_1 = (CP0AD[15:11] == 5'b1110_0);
	CS_SH1_1 = (CP1AD[15:11] == 5'b1110_0);

	SYNWR0_1 = CS_IN0_1 & (CP0AD[1:0]==2) & CP0WR;
	SYNWR1_1 = CS_IN1_1 & (CP1AD[1:0]==2) & CP1WR;

	if (HWTYPE == `HW_RAIDERS5) begin
		CS_IN0_1 = 0;
		CS_IN1_1 = 0;

		CS_SH0_1 = (CP0AD[15:11] == 5'b1110_0);
		CS_SH1_1 = (CP1AD[15:11] == 5'b1010_0);

		SYNWR0_1 = 0;
		SYNWR1_1 = 0;
	end else if (HWTYPE == `HW_NOVA2001) begin
		CS_IN0_1 = (CP0AD[15:4] == 12'hC00 && (CP0AD[3:1] == 3'b011 || CP0AD[3:1] == 3'b111));
		CS_IN1_1 = 0;

		CS_SH0_1 = (CP0AD[15:11] == 5'b1110_0);
		CS_SH1_1 = 0;

		SYNWR0_1 = 0;
		SYNWR1_1 = 0;
	end else if (HWTYPE == `HW_PKUNWAR) begin
		CS_IN0_1 = 0;
		CS_IN1_1 = 0;

		CS_SH0_1 = (CP0AD[15:11] == 5'b1100_0);
		CS_SH1_1 = 0;

		SYNWR0_1 = 0;
		SYNWR1_1 = 0;
	end
end

endmodule

