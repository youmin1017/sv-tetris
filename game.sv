// User operations
enum { DOWN, LEFT, RIGHT, ROTATE } operations;

module game(
	output logic[0:7] data_out[8],
	output logic[3:0] com_score,
   output logic[7:0] seg_score,
	input  logic clk_1000, clk_6, restart,
   input  logic[3:0] op
);

logic[3:0] score[3:0]; // BCD score
bit[0:7] Screen[8];
int T[4][2];
int center[2];
int typeid, cnt, errno, gravity, score_idx;
bit newT;
bit gameend;
parameter bit[0:7] NEW_GAME[8] = '{
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111,
    8'b11111111};
	 
	 
parameter bit[0:7] END_GAME[8] = '{
    8'b01111110,
    8'b10111101,
    8'b11011011,
    8'b11100111,
    8'b11100111,
    8'b11011011,
    8'b10111101,
    8'b01111110};

initial begin
  Screen = NEW_GAME;
  genTetromino(0, T, center, typeid);
  gravity = 0;
  score_idx = 0;
  com_score = 4'b1110;
  gameend = 1;
end

always @( posedge clk_1000 ) begin
  data2out(Screen, data_out);
  score_idx = (score_idx+1) % 4;
  bcd2seg(score[score_idx], seg_score);
  com_score = {com_score[2:0], com_score[3]};
  if(cnt == 2_100_000_000) cnt <= 0;
  // if(needed_generate_new_tetromino == 2) genTetromino(cnt%7, T, center, typeid);
  cnt <= cnt+1;
 end
 
always_ff @( posedge clk_6 ) begin
  if(restart) begin
    Screen = NEW_GAME;
    genTetromino(cnt%7, T, center, typeid);
	 for ( int i = 0; i < 4; i++ ) begin
		score[i] <= 4'b0000;
	 end
	 gameend = 1;
  end
  
  gravity <= (gravity+1)%6; // this gravity is equal to 3hz
  if( gravity == 3 && gameend ) begin:one 
    newT = 1;
    move(DOWN, Screen, T, center , newT);
	 gameend = 1;
	 if( newT ) begin
	   check_horizontal(Screen);
		score[0] <= ( score[0] == 9 ) ? 0 : score[0] + 1;
      score[1] <= ( score[0] == 9 ) ? score[1] + 1  : score[1];
      score[2] <= ( score[1] == 9 && score[0] == 9 ) ? score[2] + 1 : score[2];
      score[3] <= ( score[2] == 9 && score[1] == 9 && score[0] == 9 ) ? score[3] + 1  : score[3];
		genTetromino(cnt%7, T, center, typeid);
    end
  end
   
  if( op && gameend) begin
    case(op)
      4'b0001: move(RIGHT , Screen, T, center, newT);
      4'b0010: move(ROTATE, Screen, T, center, newT);
      4'b0100: move(DOWN  , Screen, T, center, newT);
      4'b1000: move(LEFT  , Screen, T, center, newT);
      default: errno <= 0;
    endcase
  end
end



task genTetromino (
  input  int id,
  output int tetromino[4][2],
  output int center   [2],
  output int typeid
);
// Tetrominos
  parameter int I[4][2] = '{  '{1, 2}, '{1, 3}, '{1, 4}, '{1, 5} }; //I
  parameter int J[4][2] = '{  '{0, 2}, '{1, 2}, '{1, 3}, '{1, 4} }; //J
  parameter int L[4][2] = '{  '{1, 2}, '{1, 3}, '{1, 4}, '{0, 4} }; //L
  parameter int O[4][2] = '{  '{0, 3}, '{0, 4}, '{1, 3}, '{1, 4} }; //O
  parameter int S[4][2] = '{  '{1, 2}, '{1, 3}, '{0, 3}, '{0, 4} }; //S
  parameter int T[4][2] = '{  '{1, 2}, '{1, 3}, '{1, 4}, '{0, 3} }; //T
  parameter int Z[4][2] = '{  '{0, 2}, '{0, 3}, '{1, 3}, '{1, 4} }; //Z 
// Rotation Center
  parameter int Cen[7][2] = '{ '{3, 7}, '{2, 6}, '{2, 6}, '{3, 7}, '{2, 6}, '{2, 6}, '{2, 6} }; 
  
  bit check = 1;
  typeid = id;
  center = Cen[id];
  case(id)
    0: tetromino = I;
    1: tetromino = J;
    2: tetromino = L;
    3: tetromino = O;
    4: tetromino = S;
    5: tetromino = T;
    6: tetromino = Z;
  endcase
 
  // if new tetromino hit cell
  if(gameover(Screen, tetromino, gameend ))begin
		Screen = END_GAME;
		check = 0;
  end
  
  // After new tetromino generated, show it.
  if (check) begin
		enable_tetromino(1, Screen, tetromino);
  end
  
  
endtask

task automatic enable_tetromino(
  input bit show,
  ref bit[0:7] Screen[8],
  ref int T[4][2]
);
  for( int i=0; i < 4; ++i ) begin
    Screen[T[i][0]][T[i][1]] = ~show;
  end

endtask

task automatic move( int op, ref bit[0:7] Screen[8], ref int T[4][2], ref int center[2], ref bit newT);
  
  // Remove the previous state of Tetromino
  enable_tetromino( 0, Screen, T);
  
  if( detect_conflict(op, Screen, T, center ) ) begin
    enable_tetromino( 1, Screen, T );
	 disable move;
  end
  
  // Update the Tetromino state
  for( int i=0; i < 4; ++i ) begin
    case(op)
	   DOWN  : T[i][0] += 1;
		LEFT  : T[i][1] -= 1;
		RIGHT : T[i][1] += 1;
		ROTATE: rotate(T[i], center);
		default: T[i] = T[i];
    endcase
    Screen[T[i][0]][T[i][1]] = 0;
  end
  
  // move center
  case(op)
    DOWN : center[0] += 2;
    LEFT : center[1] -= 2;
    RIGHT: center[1] += 2;
    default: center = center;
  endcase
  
  // if task going here represent that doesn't need to generate new tetromino
  newT = 0; 

endtask

function automatic bit detect_conflict(int op, ref bit[0:7] Screen[8], ref int T[4][2], ref int center[2]);
  int R[2];
  for(int i=0; i < 4; ++i) begin
    case(op)
	   DOWN  : if( Screen[ T[i][0]+1 ][ T[i][1]   ] == 0 || T[i][0]+1 > 7 ) detect_conflict = 1;
	   LEFT  : if( Screen[ T[i][0]   ][ T[i][1]-1 ] == 0 || T[i][1]-1 < 0 ) detect_conflict = 1;
		RIGHT : if( Screen[ T[i][0]   ][ T[i][1]+1 ] == 0 || T[i][1]+1 > 7 ) detect_conflict = 1;
		ROTATE: begin
	     R[0] = (center[0] - center[1] + T[i][1]*2)/2;
		  R[1] = (center[1] + center[0] - T[i][0]*2)/2;
		  if( Screen[ R[0] ][ R[1] ] == 0 ||
		                            R[0] < 0 ||
				                      R[0] > 7 ||
		                            R[1] < 0 ||
		                            R[1] > 7 ) detect_conflict = 1;
		end
		default: detect_conflict = 1;
    endcase
  end
endfunction

task automatic rotate(
  ref int T[2],
  ref int center[2]
);
// |0 -1||x|-->|x'| which is rotation matrix, rotating by 90 degree
// |1  0||y|-->|y'| converting x, y to 2x, 2y is to avoid floating point arithmetic
  int y = T[0]*2 - center[0];
  int x = T[1]*2 - center[1];
  T[0] = (center[0] + x)/2;
  T[1] = (center[1] - y)/2;
endtask

function automatic bit  gameover(ref bit [0:7] Screen[8], ref int T[4][2], ref bit gameend);
		for (int i = 0; i < 4; ++i)begin
			if ( Screen[ T[i][0] ][ T[i][1] ] == 0 )begin
				gameend = 0;
				gameover = 1;
			end
		end
endfunction

task automatic check_horizontal( ref bit[0:7] Screen[8]);
  for( int i=0; i < 8; ++i ) begin
    if( Screen[i] == 8'b00000000 ) begin
	   drop(i, Screen);
	 end
  end
endtask

task automatic drop(int idx, ref bit[0:7] Screen[8]);
  parameter bit[0:7] newLine = 8'b11111111;
  for( int i=idx; i > 0; --i ) begin
    Screen[i] = Screen[i-1];
  end
  Screen[0] = newLine;
endtask

/*This task could conver normal 2d data to 8x8 LED needed data*/
task automatic data2out(
  input  bit  [0:7] data_in [7:0],
  output logic[0:7] data_out[7:0]
);

  for( int i=0; i < 8; ++i ) begin
    data_out[i] <= {data_in[0][i],data_in[1][i],data_in[2][i],data_in[3][i],
                    data_in[4][i],data_in[5][i],data_in[6][i],data_in[7][i],};
  end

endtask

task automatic bcd2seg(
  input       [3:0] bcd,
  output logic[7:0] seg
);

//always block for converting bcd digit into 7 segment format
   case (bcd) //case statement
    0 : seg = 7'b00000001;
    1 : seg = 7'b01001111;
    2 : seg = 7'b00010010;
    3 : seg = 7'b00000110;
    4 : seg = 7'b01001100;
    5 : seg = 7'b00100100;
    6 : seg = 7'b00100000;
    7 : seg = 7'b00001111;
    8 : seg = 7'b00000000;
    9 : seg = 7'b00000100;
    default : seg = 7'b1111111; 
   endcase
	
	
endtask

endmodule
