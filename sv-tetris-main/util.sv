module divfreq1000HZ(input CLK, output reg CLK_div);
  reg [24:0] Count;
  always @(posedge CLK) begin
    if(Count > 25123) begin
      Count <= 25'b0;
      CLK_div <= ~CLK_div;
    end else Count <= Count + 1'b1;
  end
endmodule

module divfreq6HZ(input CLK, output reg CLK_div);
  reg [24:0] Count;
  always @(posedge CLK) begin
    if(Count > 4_166_667) begin
      Count <= 25'b0;
      CLK_div <= ~CLK_div;
    end else Count <= Count + 1'b1;
  end
endmodule

module divfreq1HZ(input CLK, output reg CLK_div);
  reg [24:0] Count;
  always @(posedge CLK) begin
    if(Count > 25000000) begin
      Count <= 25'b0;
      CLK_div <= ~CLK_div;
    end else Count <= Count + 1'b1;
  end
endmodule
