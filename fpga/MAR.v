module MAR(
	input [15:0] ControlSignals,	
	inout [7:0] DataBus,
	
	output [3:0] AddressToMemory,
		
	input clk, 
	input reset
	
);

reg [7:0] busInput;

assign AddressToMemory = busInput;

always @(posedge(clk))
begin
if (reset) begin
	busInput = 0;
end
else
begin

	if(ControlSignals[13]) begin // CMAR
		busInput =  DataBus;
	end

end	
end

endmodule