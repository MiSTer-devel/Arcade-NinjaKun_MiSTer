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
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler



	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;


assign {FB_PAL_CLK,  FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX =  (!ar) ? ( 8'd4) : (ar - 1'd1);
assign VIDEO_ARY =  (!ar) ? ( 8'd3) : 12'd0;



`include "build_id.v" 
localparam CONF_STR = {
	"A.NinjaKun;;",
        "H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O1,Aspect Ratio,Original,Wide;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O8,Difficulty,Normal,Hard;",
	"O9A,Lives,4,3,2,5;",
	"OB,1st Extra,30000,40000;",
	"OCD,2nd Extra (Every),50000,70000,90000,None;",
	"OF,Allow Continue,No,Yes;",
	"OG,Free Play,No,Yes;",
	"OH,Endless(If Free Play),No,Yes;",
	"OE,Demo Sound,Off,On;",
	"OI,Name Letters,8,3;",
	"-;",
	"R0,Reset;",
	"J1,Shot,Jump,Start 1P,Start 2P,Coin;",
	"jn,A,B,Start,Select,R;",
	"V,v",`BUILD_DATE
};


`define CABINET			1'b0				// Upright=0,Table=1
`define DIFFICULTY		~status[8]		// Hard=0,Normal=1
`define LIVES				~status[10:9]	// 00=5,01=2,10=3,11=4
`define EXTEND1ST			~status[11]		// 40000=0,30000=1
`define EXTEND2ND			~status[13:12]	// None,30000,50000,70000
`define DEMOSOUND			~status[14]		// On=0,Off=1

`define ALLOW_CONTINUE	~status[15]		// Yes=0,NO=1
`define FREEPLAY			~status[16]		// Yes=0,No=1
`define ENDLESS			~status[17]		// Yes=0,No=1 (If FreePlay)
`define NAMELETTERS 		~status[18]		// 3Letters=0,8Letters=1
`define COINAGE			3'b111			// 1C/1C


wire bCabinet  = `CABINET; 	// (upright only)


////////////////////   CLOCKS   ///////////////////

wire clk_48M;
wire clk_hdmi = clk_48M;
wire clk_sys = clk_48M;

pll pll
(
	.rst(0),
	.refclk(CLK_50M),
	.outclk_0(clk_48M)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [15:0] joystk1, joystk2;
wire [21:0] gamma_bus;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

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


///////////////////////////////////////////////////

wire hblank, vblank;
wire ce_pix;
wire hs, vs;
wire [3:0] r,g,b;

arcade_video#(256,12) arcade_video
(
	.*,

	.clk_video(clk_hdmi),

	.RGB_in({r,g,b}),
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

wire  [7:0] iDSW1 =  {`DIFFICULTY,`DEMOSOUND,`EXTEND2ND,`EXTEND1ST,`LIVES, `CABINET};	// 8'b1_0_01_1_10_0;
wire  [7:0] iDSW2 =  {`ENDLESS,`FREEPLAY,1'b0,`ALLOW_CONTINUE,`NAMELETTERS,`COINAGE};	// 8'b1_1_0_0_1_111; 

wire  [7:0] iCTR1 = ~{     2'b11,    m_start1, 1'b0, m_trig11, m_trig12, m_right1, m_left1 };
wire  [7:0] iCTR2 = ~{ ~m_coin,1'b1, m_start2, 1'b0, m_trig21, m_trig22, m_right2, m_left2 };

wire			iRST  = RESET | status[0] | buttons[1] | ioctl_download;

wire  [7:0] oPIX;
assign		POUT = {{oPIX[7:6],oPIX[1:0]},{oPIX[5:4],oPIX[1:0]},{oPIX[3:2],oPIX[1:0]}};


FPGA_NINJAKUN GameCore
(
	.RESET(iRST),.MCLK(clk_48M),

	.CTR1(iCTR1),.CTR2(iCTR2),
	.DSW1(iDSW1),.DSW2(iDSW2),

	.PH(HPOS),.PV(VPOS),
	.PCLK(PCLK),.POUT(oPIX),
	.SNDOUT(AOUT),

	.ROMCL(clk_sys),.ROMAD(ioctl_addr),.ROMDT(ioctl_dout),.ROMEN(ioctl_wr)
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


