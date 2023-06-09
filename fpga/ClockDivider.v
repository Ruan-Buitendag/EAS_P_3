module ClockDivider (
  input clk,
  output clk_out
);

reg [24:0] count = 0;
reg toggle = 0;

always @(posedge clk) begin
  if (count == 10000000) begin
    count = 0;
    toggle = ~toggle;
  end else begin
    count = count + 1;
  end
end

assign clk_out = toggle;

endmodule