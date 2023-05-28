module D0(
	input [15:0] ControlSignals,	
	inout [7:0] DataBus,
	
	output [7:0] DataToALU,
	
	input clk, 
	input reset
	
);

reg [7:0] busInput;
assign DataToALU = busInput;

assign DataBus = (ControlSignals[3]) ? busInput : 1'bz;

always @(posedge(clk))
begin
if (reset) begin
	busInput = 0;
end
else 
begin

	if(ControlSignals[9]) begin // CD0
		busInput =  DataBus;
	end

end	
end

endmodule