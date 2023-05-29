module PC(
	input [15:0] ControlSignals,	
	inout [7:0] DataBus,
		
	input clk, 
	input reset
	
);

reg [7:0] busInput;

assign DataBus = (ControlSignals[4]) ? busInput : 1'bz;


always @(posedge(clk))
begin

if (reset) begin
	busInput = 4'b0000;
end
else
begin
	
	if(ControlSignals[11]) begin // CPC
		busInput =  DataBus;
	end

end	
end

endmodule