module timer(
  output logic[3:0] com,
  output logic[7:0] seg,
  input clk_1HZ, clk_1000HZ, reset
);

logic[3:0] t[3:0]; // BCD timer
int i, t_idx;
initial begin
  t_idx = 0;
  com = 4'b1110;
end

  always_ff@(posedge clk_1HZ or posedge reset) begin
    if( reset == 1 ) begin
     for ( int i = 0; i < 4; i++ ) begin
      t[i] <= 4'b0000;
     end
    end else begin
     t[0] <= ( t[0] == 9 ) ? 0 : t[0] + 1;
     t[1] <= ( t[0] == 9 ) ? (t[1] + 1)%6  : t[1];
     t[2] <= ( t[1] == 5 && t[0] == 9 ) ? (t[2] + 1)%10 : t[2];
     t[3] <= ( t[2] == 9 && t[1] == 5 && t[0] == 9 ) ? (t[3] + 1)%6  : t[3];
    end
  end
  always_ff@(posedge clk_1000HZ) begin
    t_idx = (t_idx+1) % 4;
    bcd2seg(t[t_idx], seg);
    com = {com[2:0], com[3]};
  end
endmodule

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
