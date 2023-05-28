module IR(
	input [15:0] ControlSignals,	
	inout [7:0] DataBus,
	
	output [7:0] IRtoCU,
		
	input clk, 
	input reset
	
);

reg [7:0] busInput;

assign IRtoCU = busInput;

assign DataBus = (ControlSignals[5]) ? {4'b0, busInput[3:0]} : 1'bz;		// send only operand to bus
//assign DataBus = (ControlSignals[5]) ? busInput : 1'bz;		// send only operand to bus


always @(posedge(clk))
begin
if (reset) begin
	busInput = 0;
end
else
begin

	if(ControlSignals[10]) begin // CIR
		busInput =  DataBus;
	end	
	
end
end

endmodule