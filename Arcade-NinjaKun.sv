//============================================================================
//  Arcade: Ninja-Kun -- Majyo no Bouken --
//
//  Original implimentation and port to MiSTer by MiSTer-X 2019
//============================================================================


module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign AUDIO_MIX = 0;
assign HDMI_FREEZE = 0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX =  (!ar) ? ( 8'd4) : (ar - 1'd1);
assign VIDEO_ARY =  (!ar) ? ( 8'd3) : 12'd0;

`include "build_id.v" 
`include "rtl/defs.v"

// Status Bit Map:
//             Upper                             Lower              
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
//    XXXX            XX    XXX   
localparam CONF_STR = {
	"A.NinjaKun;;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O6,Service Mode,Off,On;",
	"-;",
	"DIP;",
	"-;",
	"H1OR,Autosave Hiscores,Off,On;",
	"P1,Pause options;",
	"P1OP,Pause when OSD is open,On,Off;",
	"P1OQ,Dim video after 10s,On,Off;",
	"-;",
	"R0,Reset;",
	"J1,Shot,Jump,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,B,Start,Select,R,L;",
	"jp,B,A,Start,,Select;",
	"V,v",`BUILD_DATE
};

// Read DIPs from MRA

reg [7:0] m_dip[8];
always @(posedge clk_sys) begin
	if (ioctl_wr) begin
		if ((ioctl_index==254) && !ioctl_addr[24:3]) m_dip[ioctl_addr[2:0]] <= ioctl_dout;
	end
end
wire bCabinet  = m_dip[0][0]; 	// (upright only)

wire service = status[6];

////////////////////   CLOCKS   ///////////////////

wire clk_48M;
wire clk_hdmi = clk_48M;
wire clk_sys = clk_24M;
wire clk_24M;

pll pll
(
	.rst(0),
	.refclk(CLK_50M),
	.outclk_0(clk_48M)
);

///////////////////////////////////////////////////

wire [63:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;
wire  [7:0] ioctl_index;
wire        ioctl_wait;

wire [15:0] joystk1, joystk2;
wire [21:0] gamma_bus;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),
	.status(status),
	.status_menumask({~hs_configured,direct_video}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait),

	.joystick_0(joystk1),
	.joystick_1(joystk2)
);


wire m_up2     = joystk2[3];
wire m_down2   = joystk2[2];
wire m_left2   = joystk2[1];
wire m_right2  = joystk2[0];
wire m_trig21  = joystk2[4];
wire m_trig22  = joystk2[5];

wire m_start1  = joystk1[6] | joystk2[6];
wire m_start2  = joystk1[7] | joystk2[7];

wire m_up1     = joystk1[3] | (bCabinet ? 1'b0 : m_up2);
wire m_down1   = joystk1[2] | (bCabinet ? 1'b0 : m_down2);
wire m_left1   = joystk1[1] | (bCabinet ? 1'b0 : m_left2);
wire m_right1  = joystk1[0] | (bCabinet ? 1'b0 : m_right2);
wire m_trig11  = joystk1[4] | (bCabinet ? 1'b0 : m_trig21);
wire m_trig12  = joystk1[5] | (bCabinet ? 1'b0 : m_trig22);

wire m_coin1   = joystk1[8];
wire m_coin2   = joystk2[8];
wire m_coin    = m_coin1|m_coin2;

wire m_pause   = joystk1[9] | joystk2[9];

// PAUSE SYSTEM
wire				pause_cpu;
wire [11:0]		rgb_out;
pause #(4,4,4,40) pause (
	.*,
	.reset(iRST),
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(~status[26:25])
);

///////////////////////////////////////////////////

wire hblank, vblank;
wire ce_pix;
wire hs, vs;
wire [3:0] r,g,b;

arcade_video#(256,12) arcade_video
(
	.*,

	.clk_video(clk_hdmi),

	.RGB_in(rgb_out),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(~hs),
	.VSync(~vs),

	.fx(status[5:3])
);

wire			PCLK;
wire  [8:0] HPOS,VPOS;
wire [11:0] POUT;
HVGEN hvgen
(
	.HPOS(HPOS),.VPOS(VPOS),.PCLK(PCLK),.iRGB(POUT),
	.oRGB({b,g,r}),.HBLK(hblank),.VBLK(vblank),.HSYN(hs),.VSYN(vs)
);
assign ce_pix = PCLK;


wire [15:0] AOUT;
assign AUDIO_L = AOUT;
assign AUDIO_R = AOUT;
assign AUDIO_S = 1'b0; // unsigned


///////////////////////////////////////////////////
wire  [7:0] iDSW1 =  m_dip[0]; //status[39:32];
wire  [7:0] iDSW2 =  m_dip[1]; //status[14:7];

wire [7:0]  iCTR1,iCTR2,iCTR3;

reg [7:0] hwtype = 255;
always @(posedge clk_sys) if (ioctl_wr & (ioctl_index==1)) hwtype <= ioctl_dout;

always @(*) begin
	iCTR1 = ~{2'b11, m_start1, 1'b0, m_trig11, m_trig12, m_right1, m_left1  };
	iCTR2 = ~{~(m_coin1 | m_coin2), ~service, m_start2, 1'b0, m_trig21, m_trig22, m_right2, m_left2 };
	iCTR3 = 0;
	if (hwtype == `HW_RAIDERS5) begin
		iCTR1 = ~{1'b0, 1'b0, m_start1, m_trig11, m_up1, m_down1, m_right1, m_left1};
		iCTR2 = ~{(m_coin1 | m_coin2), service, m_start2, m_trig21, m_up2, m_down2, m_right2, m_left2};
	end else if (hwtype == `HW_NOVA2001) begin
		iCTR1 = ~{m_trig11, m_trig12, 2'b00, m_right1, m_left1 , m_down1, m_up1};
		iCTR2 = ~{m_trig21, m_trig22, 2'b00, m_right2, m_left2, m_down2, m_up2};
		iCTR3 = ~{5'b00000, m_start2, m_start1, m_coin1 | m_coin2};
	end else if (hwtype == `HW_PKUNWAR) begin
		iCTR1 = ~{2'b00, m_start1, 2'b00, m_trig11, m_right1, m_left1  };
		iCTR2 = ~{(m_coin1 | m_coin2), service, m_start2, 2'b00, m_trig21, m_right2, m_left2 };
	end
end

wire			rom_download = ioctl_download & ioctl_index == 1'b0;
wire			iRST  = RESET | status[0] | buttons[1] | rom_download;

wire  [7:0] oPIX;
assign		POUT = {{oPIX[7:6],oPIX[1:0]},{oPIX[5:4],oPIX[1:0]},{oPIX[3:2],oPIX[1:0]}};


FPGA_NINJAKUN GameCore
(
	.RESET(iRST),.MCLK(clk_48M),

	.CTR1(iCTR1),.CTR2(iCTR2),.CTR3(iCTR3),
	.DSW1(iDSW1),
	.DSW2({(hwtype == `HW_NOVA2001 ? ~service : iDSW2[7]), iDSW2[6:0]}),
	
	.HWTYPE(hwtype),

	.PH(HPOS),.PV(VPOS),
	.PCLK(PCLK),.POUT(oPIX),
	.SNDOUT(AOUT),

	.ROMCL(clk_sys),.ROMAD(ioctl_addr),.ROMDT(ioctl_dout),.ROMEN(ioctl_wr & rom_download),

	.CLK24M(clk_24M),

	.pause(pause_cpu),

	.hs_address(hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(hs_data_in),
	.hs_write(hs_write_enable),
	.hs_access(hs_access_read|hs_access_write)
);

// HISCORE SYSTEM
// --------------
wire [15:0]hs_address;
wire [7:0] hs_data_in;
wire [7:0] hs_data_out;
wire hs_write_enable;
wire hs_access_read;
wire hs_access_write;
wire hs_pause;
wire hs_configured;

hiscore #(
	.HS_ADDRESSWIDTH(16),
	.CFG_ADDRESSWIDTH(3),
	.CFG_LENGTHWIDTH(2)
) hi (
	.*,
	.clk(clk_sys),
	.reset(iRST),
	.paused(pause_cpu),
	.autosave(status[27]),
	.ram_address(hs_address),
	.data_from_ram(hs_data_out),
	.data_to_ram(hs_data_in),
	.data_from_hps(ioctl_dout),
	.data_to_hps(ioctl_din),
	.ram_write(hs_write_enable),
	.ram_intent_read(hs_access_read),
	.ram_intent_write(hs_access_write),
	.pause_cpu(hs_pause),
	.configured(hs_configured)
);

endmodule


module HVGEN
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	input	 [11:0]		iRGB,

	output reg [11:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-9'd16;
assign VPOS = vcnt-9'd16;

always @(posedge PCLK) begin
	case (hcnt)
	    15: begin HBLK <= 0; hcnt <= hcnt+1'd1; end
		272: begin HBLK <= 1; hcnt <= hcnt+1'd1; end
		311: begin HSYN <= 0; hcnt <= hcnt+1'd1; end
		342: begin HSYN <= 1; hcnt <= 471;       end
		511: begin hcnt <= 0;
			case (vcnt)
				 15: begin VBLK <= 0; vcnt <= vcnt+1'd1; end
				207: begin VBLK <= 1; vcnt <= vcnt+1'd1; end
				235: begin VSYN <= 0; vcnt <= vcnt+1'd1; end
				242: begin VSYN <= 1; vcnt <= 492;       end 
				511: begin vcnt <= 0; end
				default: vcnt <= vcnt+1'd1;
			endcase
		end
		default: hcnt <= hcnt+1'd1;
	endcase
	oRGB <= (HBLK|VBLK) ? 12'h0 : iRGB;
end

endmodule


