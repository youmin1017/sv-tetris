module top(
  ///// 8x8 LED Screen /////
  output[7:0] DATA_R, DATA_G, DATA_B,
  output[2:0] S,
  output      En,
  
  
  
  ///// check for score or timer //////
  input check,
  output[7:0] seg,
  output[3:0] com,
  
  ///// CLK /////
  input clk,
  
  // /// User Control /////
  input down, left, right, rotate, 
  input restart, 
  
  ///// music ///////
  output  wire  beep
);

logic[0:7] data[7:0];
logic[3:0] com_timer;
logic[7:0] seg_timer;
logic[3:0] com_score;
logic[7:0] seg_score;

initial begin
  En = 1;
  S = 0;
  DATA_B = 8'b11111111;
  DATA_G = 8'b11111111;
end

divfreq1000HZ HZ_1000(clk, clk_1000);
divfreq6HZ    HZ_6(clk, clk_6);
divfreq1HZ    HZ_1(clk, clk_1);
// divfreq3HZ    HZ_3 (clk, clk_3);

game Tetris(
  .data_out(data),
  .com_score(com_score),
  .seg_score(seg_score),
  .clk_1000(clk_1000),
  .clk_6(clk_6),
  .restart(restart), 
  .op( {left, down, rotate, right} )
 );
 

timer GAME_TIMER(
  .com(com_timer),
  .seg(seg_timer),
  .clk_1HZ(clk_1),
  .clk_1000HZ(clk_1000),
  .reset(restart)
);


music GAME_MUSIC(
	.clk(clk),
	.rst_n(!restart),
	.beep(beep)
);

always@( posedge clk_1000 ) begin
  S = ( S+1 ) % 8;
  DATA_R = data[S];
  if(check) begin
		seg = seg_score;
		com = com_score;
	end
	else begin 
		seg = seg_timer;
		com = com_timer;
	end
end

endmodule
