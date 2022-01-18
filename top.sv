module top(
  ///// 8x8 LED Screen /////
  output[7:0] DATA_R, DATA_G, DATA_B,
  output[2:0] S,
  output      En,
  
  ///// CLK /////
  input clk,
  
  // /// User Control /////
  input down, left, right, rotate, 
  input restart,
  
  ///// Game Timer /////
  output[7:0] seg,
  output[3:0] com
);

logic[0:7] data[7:0];

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
  .clk_1000(clk_1000),
  .clk_6(clk_6),
  .restart(restart), 
  .op( {left, down, rotate, right} )
 );
 

timer GAME_TIMER(
  .com(com),
  .seg(seg),
  .clk_1HZ(clk_1),
  .clk_1000HZ(clk_1000),
  .reset(restart)
);

always@( posedge clk_1000 ) begin
  S = ( S+1 ) % 8;
  DATA_R = data[S];
end

endmodule
