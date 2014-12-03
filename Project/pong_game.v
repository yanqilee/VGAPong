module pong_game(//	Clock Input
  input CLOCK_50,	//	50 MHz
  input CLOCK_27,     //      27 MHz
//	Push Button
  input [3:0] KEY,      //	Pushbutton[3:0]
//	DPDT Switch
  input [17:0] SW,		//	Toggle Switch[17:0]
  //  7-SEG Displays
  output  [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
  //  LEDs
  output  [8:0]  LEDG,  //  LED Green[8:0]
  output  [17:0]  LEDR,  //  LED Red[17:0]
  //  PS2 data and clock lines		
  input	PS2_DAT,
  input	PS2_CLK,
	output LCD_ON,	// LCD Power ON/OFF
  output LCD_BLON,	// LCD Back Light ON/OFF
  output LCD_RW,	// LCD Read/Write Select, 0 = Write, 1 = Read
  output LCD_EN,	// LCD Enable
  output LCD_RS,	// LCD Command/Data Select, 0 = Command, 1 = Data
  inout [7:0] LCD_DATA,	// LCD Data bus 8 bits
//	GPIO
 inout [35:0] GPIO_0,GPIO_1,	//	GPIO Connections
//	TV Decoder
//TD_DATA,    	//	TV Decoder Data bus 8 bits
//TD_HS,		//	TV Decoder H_SYNC
//TD_VS,		//	TV Decoder V_SYNC
  output TD_RESET,	//	TV Decoder Reset
// VGA
  output VGA_CLK,   						//	VGA Clock
  output VGA_HS,							//	VGA H_SYNC
  output VGA_VS,							//	VGA V_SYNC
  output VGA_BLANK,						//	VGA BLANK
  output VGA_SYNC,						//	VGA SYNC
  output [9:0] VGA_R,   						//	VGA Red[9:0]
  output [9:0] VGA_G,	 						//	VGA Green[9:0]
  output [9:0] VGA_B   						//	VGA Blue[9:0]
);

	//pong p1(CLOCK_50, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B, SW[1], SW[0]);
	//	All inout port turn to tri-state
	assign	GPIO_0		=	36'hzzzzzzzzz;
	assign	GPIO_1		=	36'hzzzzzzzzz;

	wire RST;
	assign RST = SW[17];

	wire DLY_RST;
	Reset_Delay r0(	.iCLK(CLOCK_50),.oRESET(DLY_RST) );
	
	vga_sync s1(
   .iCLK(VGA_CTRL_CLK),
   .iRST_N(DLY_RST&~SW[17]),	
   .iRed(mVGA_R),
   .iGreen(mVGA_G),
   .iBlue(mVGA_B),
   // pixel coordinates
   .px(mCoord_X),
   .py(mCoord_Y),
   // VGA Side
   .VGA_R(VGA_R),
   .VGA_G(VGA_G),
   .VGA_B(VGA_B),
   .VGA_H_SYNC(VGA_HS),
   .VGA_V_SYNC(VGA_VS),
   .VGA_SYNC(VGA_SYNC),
   .VGA_BLANK(VGA_BLANK)
);
wire [6:0] blank = 7'b111_1111;

wire		VGA_CTRL_CLK;
wire		AUD_CTRL_CLK;
wire [9:0]	mVGA_R;
wire [9:0]	mVGA_G;
wire [9:0]	mVGA_B;
wire [9:0]	mCoord_X;
wire [9:0]	mCoord_Y;

assign	TD_RESET = 1'b1; // Enable 27 MHz

VGA_Audio_PLL 	pp1 (	
	.areset(~DLY_RST),
	.inclk0(CLOCK_27),
	.c0(VGA_CTRL_CLK),
	.c1(AUD_CTRL_CLK),
	.c2(VGA_CLK)
);

wire [9:0] r, g, b;
reg[9:0] left_pos, right_pos, ball_left, ball_top;
reg[3:0] ball_x, ball_y;
reg[29:0] counter;
wire[10:0] top, bot, left, right;

assign top = 0;
assign bot = 464;
assign left = 36;
assign right = 604;

initial begin
	left_pos = 200;
	right_pos = 200;
	ball_left = 312;
	ball_top = 232;
	ball_x = 1;
	ball_y = 1;
	counter = 0;
	counter2 = 0;
	sign_x = 0;
	sign_y = 0;
end

	// Connect dip switches to red LEDs
	assign LEDR[17:0] = SW[17:0];

	wire reset = 1'b0;
	wire [7:0] scan_code;

	reg [7:0] history[1:4];
	wire read, scan_ready;

	oneshot pulser(
		.pulse_out(read),
		.trigger_in(scan_ready),
		.clk(CLOCK_50)
	);

	keyboard kbd(
	  .keyboard_clk(PS2_CLK),
	  .keyboard_data(PS2_DAT),
	  .clock50(CLOCK_50),
	  .reset(reset),
	  .read(read),
	  .scan_ready(scan_ready),
	  .scan_code(scan_code)
	);

	always @(posedge scan_ready)
	begin
		history[4] <= history[3];
		history[3] <= history[2];
		history[2] <= history[1];
		history[1] <= scan_code;
	end

reg game_count;
//reg[32:0] win_counter;
reg sign_x, sign_y;
reg[32:0] aicounter;
reg hit_last; // 0 for left, 1 for right

always @ (posedge CLOCK_50) begin
// AI hard
	if ((~game_count & SW[5]) | (game_count & ~SW[5])) begin
		counter = counter + 1;
		if (counter == 450000) begin
			// 45 degree angle going to bottom right
			if (sign_y == 0 & sign_x == 0) begin
				ball_left = ball_left + ball_x;
				ball_top = ball_top + ball_y;
			end else if (sign_y == 1 & sign_x == 1) begin
				ball_left = ball_left - ball_x;
				ball_top = ball_top - ball_y;	
			end else if (sign_y == 1 & sign_x == 0) begin
				ball_left = ball_left + ball_x;
				ball_top = ball_top - ball_y;	
			end else begin
				ball_left = ball_left - ball_x;
				ball_top = ball_top + ball_y;	
			end
			counter = 0;
			// checking for collision against top and bottom
			if (ball_top <= top | ball_top >= bot) begin
				sign_y = ~sign_y;
			end
			if ((ball_top + 16 == left_pos & ball_left < left) | (ball_top + 16 == right_pos & ball_left + 16 > right) | (ball_top == left_pos + 80 & ball_left < left) | (ball_top == right_pos + 80 & ball_left > right + 16)) begin
				sign_y = ~sign_y;
				sign_x = ~sign_x;
				ball_x = ball_x + 1;
				ball_y = ball_y + 1;
			end
			// check collison, check angle of reflection
			if (ball_left <= left & ball_top < left_pos + 80 & ball_top + 16 > left_pos) begin
				sign_x = ~sign_x;
				ball_x = ball_x + 1;
				ball_y = ball_y + 1;
			end
			if (ball_left + 16 >= right & ball_top < right_pos + 80 & ball_top + 16 > right_pos) begin
				sign_x = ~sign_x;
				ball_x = ball_x + 1;
				ball_y = ball_y + 1;
			end
			if (ball_left <= 0) begin
				SCORE2 = SCORE2 + 1;
				left_pos = 200;
				right_pos = 200;
				ball_left = 312;
				ball_top = 232;
				ball_x = 1;
				ball_y = 1;
			end else if (ball_left >= 624) begin
				SCORE1 = SCORE1 + 1;
				left_pos = 200;
				right_pos = 200;
				ball_left = 312;
				ball_top = 232;
				ball_x = 1;
				ball_y = 1;
			end
		end
		counter2 = counter2 + 1;
		aicounter = aicounter + 1;
		if (counter2 == 60000) begin
			if (left_pos < 400 & ~KEY[2]) //& scan_code == 27 & history[2] != 240) // go down (s)
				left_pos = left_pos + 1;
			if (left_pos > 0 & ~KEY[3]) //& scan_code == 29 & history[2] != 240) // go up (w)
				left_pos = left_pos - 1;
			counter2 = 0;
		end
		if (aicounter == 40000) begin
			if (right_pos < 400 & (right_pos + 40 < ball_top + 16)) //scan_code == 114 & history[2] == 224 & history[3] != 240) // go down (down)
				right_pos = right_pos + 1;
			else if (right_pos > 0 & right_pos + 40 > ball_top + 16) //scan_code == 117 & history[2] == 224 & history[3] != 240) // go up (up)
				right_pos = right_pos - 1;
			aicounter = 0;
		end
	end
	if (SCORE1 > 9 | SCORE2 > 9) begin
		//win_counter = win_counter + 1;
		//if (win_counter == 250000000) begin
		left_pos = 200;
		right_pos = 200;
		ball_left = 312;
		ball_top = 232;
		ball_x = 0;
		ball_y = 0;
		if (SW[8]) begin
			SCORE1 = 0;
			SCORE2 = 0;
			ball_x = 1;
			ball_y = 1;
			game_count = ~game_count;
		end
	end
// AI
	else if ((~game_count & SW[4]) | (game_count & ~SW[4])) begin
		counter = counter + 1;
		if (counter == 450000) begin
			// 45 degree angle going to bottom right
			if (sign_y == 0 & sign_x == 0) begin
				ball_left = ball_left + ball_x;
				ball_top = ball_top + ball_y;
			end else if (sign_y == 1 & sign_x == 1) begin
				ball_left = ball_left - ball_x;
				ball_top = ball_top - ball_y;	
			end else if (sign_y == 1 & sign_x == 0) begin
				ball_left = ball_left + ball_x;
				ball_top = ball_top - ball_y;	
			end else begin
				ball_left = ball_left - ball_x;
				ball_top = ball_top + ball_y;	
			end
			counter = 0;
			// checking for collision against top and bottom
			if (ball_top <= top | ball_top >= bot) begin
				sign_y = ~sign_y;
			end
			if ((ball_top + 16 == left_pos & ball_left < left) | (ball_top + 16 == right_pos & ball_left + 16 > right) | (ball_top == left_pos + 80 & ball_left < left) | (ball_top == right_pos + 80 & ball_left > right + 16)) begin
				sign_y = ~sign_y;
				sign_x = ~sign_x;
				ball_x = ball_x + 1;
				ball_y = ball_y + 1;
			end
			// check collison, check angle of reflection
			if (ball_left <= left & ball_top < left_pos + 80 & ball_top + 16 > left_pos) begin
				sign_x = ~sign_x;
				ball_x = ball_x + 1;
				ball_y = ball_y + 1;
			end
			if (ball_left + 16 >= right & ball_top < right_pos + 80 & ball_top + 16 > right_pos) begin
				sign_x = ~sign_x;
				ball_x = ball_x + 1;
				ball_y = ball_y + 1;
			end
			if (ball_left <= 0) begin
				SCORE2 = SCORE2 + 1;
				left_pos = 200;
				right_pos = 200;
				ball_left = 312;
				ball_top = 232;
				ball_x = 1;
				ball_y = 1;
			end else if (ball_left >= 624) begin
				SCORE1 = SCORE1 + 1;
				left_pos = 200;
				right_pos = 200;
				ball_left = 312;
				ball_top = 232;
				ball_x = 1;
				ball_y = 1;
			end
		end
		counter2 = counter2 + 1;
		aicounter = aicounter + 1;
		if (counter2 == 100000) begin
			if (left_pos < 400 & ~KEY[2]) //& scan_code == 27 & history[2] != 240) // go down (s)
				left_pos = left_pos + 1;
			if (left_pos > 0 & ~KEY[3]) //& scan_code == 29 & history[2] != 240) // go up (w)
				left_pos = left_pos - 1;
			counter2 = 0;
		end
		if (aicounter == 100000) begin
			if (right_pos < 400 & (right_pos + 40 < ball_top + 16)) //scan_code == 114 & history[2] == 224 & history[3] != 240) // go down (down)
				right_pos = right_pos + 1;
			else if (right_pos > 0 & right_pos + 40 > ball_top + 16) //scan_code == 117 & history[2] == 224 & history[3] != 240) // go up (up)
				right_pos = right_pos - 1;
			aicounter = 0;
		end
	end
	if (SCORE1 > 9 | SCORE2 > 9) begin
		//win_counter = win_counter + 1;
		//if (win_counter == 250000000) begin
		left_pos = 200;
		right_pos = 200;
		ball_left = 312;
		ball_top = 232;
		ball_x = 0;
		ball_y = 0;
		if (SW[8]) begin
			SCORE1 = 0;
			SCORE2 = 0;
			ball_x = 1;
			ball_y = 1;
			game_count = ~game_count;
		end
	end
	// hardcore mode
	else if ((~game_count & SW[2]) | (game_count & ~SW[2])) begin
		counter = counter + 1;
		if (counter == 450000) begin
			// 45 degree angle going to bottom right
			if (sign_y == 0 & sign_x == 0) begin
				ball_left = ball_left + ball_x;
				ball_top = ball_top + ball_y;
			end else if (sign_y == 1 & sign_x == 1) begin
				ball_left = ball_left - ball_x;
				ball_top = ball_top - ball_y;	
			end else if (sign_y == 1 & sign_x == 0) begin
				ball_left = ball_left + ball_x;
				ball_top = ball_top - ball_y;	
			end else begin
				ball_left = ball_left - ball_x;
				ball_top = ball_top + ball_y;	
			end
			counter = 0;
			// checking for collision against top and bottom
			if (ball_top <= top | ball_top >= bot) begin
				sign_y = ~sign_y;
			end
			if ((ball_top + 16 == left_pos & ball_left < left) | (ball_top + 16 == right_pos & ball_left + 16 > right) | (ball_top == left_pos + 80 & ball_left < left) | (ball_top == right_pos + 80 & ball_left > right + 16)) begin
				ball_x = ball_x + 1;
				ball_y = ball_y + 1;
				sign_y = ~sign_y;
				sign_x = ~sign_x;
			end
			// check collison, check angle of reflection
			if (ball_left == left & ball_top < left_pos + 80 & ball_top + 16 > left_pos) begin
				ball_x = ball_x + 1;
				ball_y = ball_y + 1;
				sign_x = ~sign_x;
			end
			if (ball_left + 16 == right & ball_top < right_pos + 80 & ball_top + 16 > right_pos) begin
				ball_x = ball_x + 1;
				ball_y = ball_y + 1;
				sign_x = ~sign_x;
			end
			if (ball_left <= 0) begin
				SCORE2 = SCORE2 + 1;
				left_pos = 200;
				right_pos = 200;
				ball_left = 312;
				ball_top = 232;
				ball_x = 1;
				ball_y = 1;
			end else if (ball_left >= 624) begin
				SCORE1 = SCORE1 + 1;
				left_pos = 200;
				right_pos = 200;
				ball_left = 312;
				ball_top = 232;
				ball_x = 1;
				ball_y = 1;
			end
		end
		counter2 = counter2 + 1;
		if (counter2 == 100000) begin
			if (left_pos < 400 & ~KEY[2]) //& scan_code == 27 & history[2] != 240) // go down (s)
				left_pos = left_pos + 1;
			if (left_pos > 0 & ~KEY[3]) //& scan_code == 29 & history[2] != 240) // go up (w)
				left_pos = left_pos - 1;
			if (right_pos < 400 & ~KEY[1]) //scan_code == 114 & history[2] == 224 & history[3] != 240) // go down (down)
				right_pos = right_pos + 1;
			if (right_pos > 0 & ~KEY[0]) //scan_code == 117 & history[2] == 224 & history[3] != 240) // go up (up)
				right_pos = right_pos - 1;
			counter2 = 0;
		end
	end
	if (SCORE1 > 9 | SCORE2 > 9) begin
		//win_counter = win_counter + 1;
		//if (win_counter == 250000000) begin
		left_pos = 200;
		right_pos = 200;
		ball_left = 312;
		ball_top = 232;
		ball_x = 0;
		ball_y = 0;
		if (SW[8]) begin
			SCORE1 = 0;
			SCORE2 = 0;
			ball_x = 1;
			ball_y = 1;
			game_count = ~game_count;
		end
	end
	
// for casuals
	else if ((~game_count & SW[1]) | (game_count & ~SW[1])) begin
		counter = counter + 1;
		if (counter == 300000) begin
			// 45 degree angle going to bottom right
			if (sign_y == 0 & sign_x == 0) begin
				ball_left = ball_left + ball_x;
				ball_top = ball_top + ball_y;
			end else if (sign_y == 1 & sign_x == 1) begin
				ball_left = ball_left - ball_x;
				ball_top = ball_top - ball_y;	
			end else if (sign_y == 1 & sign_x == 0) begin
				ball_left = ball_left + ball_x;
				ball_top = ball_top - ball_y;	
			end else begin
				ball_left = ball_left - ball_x;
				ball_top = ball_top + ball_y;	
			end
			counter = 0;
			// checking for collision against top and bottom
			if (ball_top <= top | ball_top >= bot) begin
				sign_y = ~sign_y;
			end
			if ((ball_top + 16 == left_pos & ball_left < left) | (ball_top + 16 == right_pos & ball_left + 16 > right) | (ball_top == left_pos + 80 & ball_left < left) | (ball_top == right_pos + 80 & ball_left > right + 16)) begin
				sign_y = ~sign_y;
				sign_x = ~sign_x;
			end
			// check collison, check angle of reflection
			if (ball_left == left & ball_top < left_pos + 80 & ball_top + 16 > left_pos) begin
				sign_x = ~sign_x;
			end
			if (ball_left + 16 == right & ball_top < right_pos + 80 & ball_top + 16 > right_pos) begin
				sign_x = ~sign_x;
			end
			if (ball_left <= 0) begin
				SCORE2 = SCORE2 + 1;
				left_pos = 200;
				right_pos = 200;
				ball_left = 312;
				ball_top = 232;
				ball_x = 1;
				ball_y = 1;
			end else if (ball_left >= 624) begin
				SCORE1 = SCORE1 + 1;
				left_pos = 200;
				right_pos = 200;
				ball_left = 312;
				ball_top = 232;
				ball_x = 1;
				ball_y = 1;
			end
		end
		counter2 = counter2 + 1;
		if (counter2 == 200000) begin
			if (left_pos < 400 & ~KEY[2]) //& scan_code == 27 & history[2] != 240) // go down (s)
				left_pos = left_pos + 1;
			if (left_pos > 0 & ~KEY[3]) //& scan_code == 29 & history[2] != 240) // go up (w)
				left_pos = left_pos - 1;
			if (right_pos < 400 & ~KEY[1]) //scan_code == 114 & history[2] == 224 & history[3] != 240) // go down (down)
				right_pos = right_pos + 1;
			if (right_pos > 0 & ~KEY[0]) //scan_code == 117 & history[2] == 224 & history[3] != 240) // go up (up)
				right_pos = right_pos - 1;
			counter2 = 0;
		end
	end
	if (SCORE1 > 9 | SCORE2 > 9) begin
		//win_counter = win_counter + 1;
		//if (win_counter == 250000000) begin
		left_pos = 200;
		right_pos = 200;
		ball_left = 312;
		ball_top = 232;
		ball_x = 0;
		ball_y = 0;
		if (SW[8]) begin
			SCORE1 = 0;
			SCORE2 = 0;
			ball_x = 1;
			ball_y = 1;
			game_count = ~game_count;
		end
	end

end

reg [26:0] counter2;
// always @ (CLOCK_50) begin if (scan_code == 2'h1D)

bars c1(mCoord_X, mCoord_Y, r, g, b, left_pos, right_pos, ball_left, ball_top);

assign LEDG[7:0] = scan_code;

wire [9:0] gray = (mCoord_X<80 || mCoord_X>560? 10'h000:
	(mCoord_Y/15)<<5 | (mCoord_X-80)/15);
	
wire s = SW[0];
assign mVGA_R = (s? gray: r);
assign mVGA_G = (s? gray: g);
assign mVGA_B = (s? gray: b);

//****************************************************************************************
// turn LCD ON
assign	LCD_ON		=	1'b1;
assign	LCD_BLON	=	1'b1;
	
	// blank unused 7-segment digits
assign HEX0 = 7'b111_1111;
assign HEX1 = 7'b111_1111;
assign HEX2 = 7'b111_1111;
assign HEX3 = 7'b111_1111;
assign HEX4 = 7'b111_1111;
assign HEX5 = 7'b111_1111;
assign HEX6 = 7'b111_1111;
assign HEX7 = 7'b111_1111;

reg [3:0] SCORE1, SCORE2;

LCD_PRINTKEY u1(
// Host Side
   .iCLK(CLOCK_50),
   .iRST_N(DLY_RST),
	.KEY(scan_code),
// LCD Side
   .LCD_DATA(LCD_DATA),
   .LCD_RW(LCD_RW),
   .LCD_EN(LCD_EN),
   .LCD_RS(LCD_RS),
	.SCORE1(SCORE1),
	.SCORE2(SCORE2)
);
endmodule

module	LCD_PRINTKEY (
// Host Side
  input iCLK,iRST_N,
  input [7:0] KEY,
// LCD Side
  output [7:0] 	LCD_DATA,
  output LCD_RW,LCD_EN,LCD_RS,
  input [3:0] SCORE1, SCORE2
);
//	Internal Wires/Registers
reg	[5:0]	LUT_INDEX;
reg	[8:0]	LUT_DATA;
reg	[5:0]	mLCD_ST;
reg	[17:0]	mDLY;
reg		mLCD_Start;
reg	[7:0]	mLCD_DATA, lastkey, lastkey2;
reg		mLCD_RS;
wire		mLCD_Done;
reg[9:0] state1, state2;

parameter	LCD_INTIAL	=	0;
parameter	LCD_LINE1	=	5;
parameter	LCD_CH_LINE	=	LCD_LINE1+16;
parameter	LCD_LINE2	=	LCD_LINE1+16+1;
parameter	LUT_SIZE	=	LCD_LINE1+32+1;

always begin
	case (SCORE1)
	0: state1 = 9'h130;
	1: state1 = 9'h131;
	2: state1 = 9'h132;
	3: state1 = 9'h133;
	4: state1 = 9'h134;
	5: state1 = 9'h135;
	6: state1 = 9'h136;
	7: state1 = 9'h137;
	8: state1 = 9'h138;
	9: state1 = 9'h139;
	default: state1 = 9'h120;
	endcase
	case (SCORE2)
	0: state2 = 9'h130;
	1: state2 = 9'h131;
	2: state2 = 9'h132;
	3: state2 = 9'h133;
	4: state2 = 9'h134;
	5: state2 = 9'h135;
	6: state2 = 9'h136;
	7: state2 = 9'h137;
	8: state2 = 9'h138;
	9: state2 = 9'h139;
	default: state2 = 9'h120;
	endcase
end

always@(posedge iCLK or negedge iRST_N)
begin
	if(!iRST_N)
	begin
		LUT_INDEX	<=	0;
		mLCD_ST		<=	0;
		mDLY		<=	0;
		mLCD_Start	<=	0;
		mLCD_DATA	<=	0;
		mLCD_RS		<=	0;
	end
	else
	begin
		if(LUT_INDEX<LUT_SIZE)
		begin
			case(mLCD_ST)
			0:	begin
					mLCD_DATA	<=	LUT_DATA[7:0];
					mLCD_RS		<=	LUT_DATA[8];
					mLCD_Start	<=	1;
					mLCD_ST		<=	1;
				end
			1:	begin
					if(mLCD_Done)
					begin
						mLCD_Start	<=	0;
						mLCD_ST		<=	2;					
					end
				end
			2:	begin
					if(mDLY<18'h3FFFE)
					mDLY	<=	mDLY + 1'b1;
					else
					begin
						mDLY	<=	0;
						mLCD_ST	<=	3;
					end
				end
			3:	begin
					LUT_INDEX	<=	LUT_INDEX + 1'b1;
					mLCD_ST	<=	0;
				end
			endcase
		end
		else if (lastkey != SCORE1 | lastkey2 != SCORE2)
			begin
				LUT_INDEX <= 0;
				lastkey = SCORE1;
				lastkey2 = SCORE2;
			end
	end
end

always
begin
	case(LUT_INDEX)
	//	Initial
	LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
	LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
	LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
	LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
	LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
	//	Line 1
		LCD_LINE1+0:	LUT_DATA	<=	9'h150;	//	Player 1:
		LCD_LINE1+1:	LUT_DATA	<=	9'h16C;
		LCD_LINE1+2:	LUT_DATA	<=	9'h161;
		LCD_LINE1+3:	LUT_DATA	<=	9'h179;
		LCD_LINE1+4:	LUT_DATA	<=	9'h165; 
		LCD_LINE1+5:	LUT_DATA	<=	9'h172; 
		LCD_LINE1+6:	LUT_DATA	<=	9'h120;
		
		LCD_LINE1+7:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h131;	//	Player 1:
		else if (SCORE2 < 10 & SCORE1 > 9)
			LUT_DATA	<=	9'h131;	//	Player 1 Wins
		else
			LUT_DATA	<=	9'h132;	//	Player 2 Wins
		end
		
		LCD_LINE1+8:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h13A;	//	Player 1:
		else
			LUT_DATA	<=	9'h120;	//	Player X Wins
		end
		LCD_LINE1+9:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h120;	//	Player 1:
		else
			LUT_DATA	<=	9'h157;	//	Player X Wins
		end
		LCD_LINE1+10:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	state1;	//	Player 1:
		else
			LUT_DATA	<=	9'h169;	//	Player X Wins
		end
		LCD_LINE1+11:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h120;	//	Player 1:
		else
			LUT_DATA	<=	9'h16E;	//	Player X Wins
		end
		LCD_LINE1+12:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h120;	//	Player 1:
		else
			LUT_DATA	<=	9'h173;	//	Player X Wins
		end
		LCD_LINE1+13:	LUT_DATA	<=	9'h120;
		LCD_LINE1+14:	LUT_DATA	<=	9'h120;
		LCD_LINE1+15:	LUT_DATA	<=	9'h120;

	//	Change Line
	LCD_CH_LINE:	LUT_DATA	<=	9'h0C0;
	//	Line 2
	LCD_LINE2+0:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h150;	//	Player 2:
		else
			LUT_DATA	<=	9'h120;	
		end
	LCD_LINE2+1:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h16C;	//	Player 2:
		else
			LUT_DATA	<=	9'h120;	
		end
	LCD_LINE2+2:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h161;	//	Player 2:
		else
			LUT_DATA	<=	9'h120;	
		end
	LCD_LINE2+3:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h179;	//	Player 2:
		else
			LUT_DATA	<=	9'h120;	
		end
	LCD_LINE2+4:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h165;	//	Player 2:
		else
			LUT_DATA	<=	9'h120;	
		end
	LCD_LINE2+5:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h172;	//	Player 2:
		else
			LUT_DATA	<=	9'h120;	
		end
	LCD_LINE2+6:	LUT_DATA	<=	9'h120;
	LCD_LINE2+7:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h132;	//	Player 2:
		else
			LUT_DATA	<=	9'h120;	
		end
	LCD_LINE2+8:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	9'h13A;	//	Player 2:
		else
			LUT_DATA	<=	9'h120;	
		end
	LCD_LINE2+9:	LUT_DATA	<=	9'h120;
	LCD_LINE2+10:	begin if (SCORE1 < 10 & SCORE2 < 10)
			LUT_DATA	<=	state2; // score here
		else
			LUT_DATA	<=	9'h120;	
		end
	LCD_LINE2+11:	LUT_DATA	<=	9'h120;
	LCD_LINE2+12:	LUT_DATA	<=	9'h120;
	LCD_LINE2+13:	LUT_DATA	<=	9'h120;
	LCD_LINE2+14:	LUT_DATA	<=	9'h120;
	LCD_LINE2+15:	LUT_DATA	<=	9'h120;
	default:		LUT_DATA	<=	9'dx ;
	endcase
end

LCD_Controller u0(
//    Host Side
.iDATA(mLCD_DATA),
.iRS(mLCD_RS),
.iStart(mLCD_Start),
.oDone(mLCD_Done),
.iCLK(iCLK),
.iRST_N(iRST_N),
//    LCD Interface
.LCD_DATA(LCD_DATA),
.LCD_RW(LCD_RW),
.LCD_EN(LCD_EN),
.LCD_RS(LCD_RS)    );

endmodule
//****************************************************************************************
