module bars(input [9:0] x, input [9:0] y,
	output [9:0] red, output [9:0] green, output [9:0] blue, input [9:0] left_pos,
	input [9:0] right_pos, input [9:0] ball_pos_x, input [9:0] ball_pos_y);
	
	reg [2:0] idx;
	wire [9:0] left_bot, right_bot, ball_right, ball_bot;
	assign left_bot = left_pos + 80;
	assign right_bot = right_pos + 80;
	assign ball_right = ball_pos_x + 16;
	assign ball_bot = ball_pos_y + 16;
	
	always @(x) begin
		//first row
		if (x < 80 && y < 60) idx <= 3'd0;
		else if (x < 160 && y < 60) idx <= 3'd1;
		else if (x < 240 && y < 60) idx <= 3'd0;
		else if (x < 320 && y < 60) idx <= 3'd1;
		else if (x < 400 && y < 60) idx <= 3'd0;
		else if (x < 480 && y < 60) idx <= 3'd1;
		else if (x < 560 && y < 60) idx <= 3'd0;
		else if (x < 640 && y < 60) idx <= 3'd1;
		//second row
		else if (x < 80 && y < 120) idx <= 3'd1;
		else if (x < 160 && y < 120) idx <= 3'd0;
		else if (x < 240 && y < 120) idx <= 3'd1;
		else if (x < 320 && y < 120) idx <= 3'd0;
		else if (x < 400 && y < 120) idx <= 3'd1;
		else if (x < 480 && y < 120) idx <= 3'd0;
		else if (x < 560 && y < 120) idx <= 3'd1;
		else if (x < 640 && y < 120) idx <= 3'd0;
		//third row
		else if (x < 80 && y < 180) idx <= 3'd0;
		else if (x < 160 && y < 180) idx <= 3'd1;
		else if (x < 240 && y < 180) idx <= 3'd0;
		else if (x < 320 && y < 180) idx <= 3'd1;
		else if (x < 400 && y < 180) idx <= 3'd0;
		else if (x < 480 && y < 180) idx <= 3'd1;
		else if (x < 560 && y < 180) idx <= 3'd0;
		else if (x < 640 && y < 180) idx <= 3'd1;
		//fourth row
		else if (x < 80 && y < 240) idx <= 3'd1;
		else if (x < 160 && y < 240) idx <= 3'd0;
		else if (x < 240 && y < 240) idx <= 3'd1;
		else if (x < 320 && y < 240) idx <= 3'd0;
		else if (x < 400 && y < 240) idx <= 3'd1;
		else if (x < 480 && y < 240) idx <= 3'd0;
		else if (x < 560 && y < 240) idx <= 3'd1;
		else if (x < 640 && y < 240) idx <= 3'd0;
		//fifth row
		else if (x < 80 && y < 300) idx <= 3'd0;
		else if (x < 160 && y < 300) idx <= 3'd1;
		else if (x < 240 && y < 300) idx <= 3'd0;
		else if (x < 320 && y < 300) idx <= 3'd1;
		else if (x < 400 && y < 300) idx <= 3'd0;
		else if (x < 480 && y < 300) idx <= 3'd1;
		else if (x < 560 && y < 300) idx <= 3'd0;
		else if (x < 640 && y < 300) idx <= 3'd1;
		//sixth row
		else if (x < 80 && y < 360) idx <= 3'd1;
		else if (x < 160 && y < 360) idx <= 3'd0;
		else if (x < 240 && y < 360) idx <= 3'd1;
		else if (x < 320 && y < 360) idx <= 3'd0;
		else if (x < 400 && y < 360) idx <= 3'd1;
		else if (x < 480 && y < 360) idx <= 3'd0;
		else if (x < 560 && y < 360) idx <= 3'd1;
		else if (x < 640 && y < 360) idx <= 3'd0;
		//seventh row
		else if (x < 80 && y < 420) idx <= 3'd0;
		else if (x < 160 && y < 420) idx <= 3'd1;
		else if (x < 240 && y < 420) idx <= 3'd0;
		else if (x < 320 && y < 420) idx <= 3'd1;
		else if (x < 400 && y < 420) idx <= 3'd0;
		else if (x < 480 && y < 420) idx <= 3'd1;
		else if (x < 560 && y < 420) idx <= 3'd0;
		else if (x < 640 && y < 420) idx <= 3'd1;
		//last row
		else if (x < 80 && y > 419) idx <= 3'd1;
		else if (x < 160 && y > 419) idx <= 3'd0;
		else if (x < 240 && y > 419) idx <= 3'd1;
		else if (x < 320 && y > 419) idx <= 3'd0;
		else if (x < 400 && y > 419) idx <= 3'd1;
		else if (x < 480 && y > 419) idx <= 3'd0;
		else if (x < 560 && y > 419) idx <= 3'd1;
		else if (x < 640 && y > 419) idx <= 3'd0;
		else idx <= 3'd0;
		//hardcode paddle
		if (x > 20 & x < 36 & y > left_pos & y < left_bot) idx <= 3'd7;
		if (x > 604 & x < 620 & y > right_pos & y < right_bot) idx <=3'd7;
		//hardcode ball
		if (x > ball_pos_x & x < ball_right & y > ball_pos_y & y < ball_bot) idx <=3'd7;
	end
	assign red = (idx[0]? 10'h3ff: 10'h000);
	assign green = (idx[1]? 10'h3ff: 10'h000);
	assign blue = (idx[2]? 10'h3ff: 10'h000);

endmodule
