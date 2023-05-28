module MBR(
	input [15:0] ControlSignals,	
	inout [7:0] DataBus,
		
	input clk, 
	input reset
	
);

reg [7:0] busInput;

assign DataBus = (ControlSignals[6]) ? busInput : 1'bz;

always @(posedge(clk))
begin
if (reset) begin
	busInput = 0;
end
else
begin

	if(ControlSignals[12]) begin // CMBR
		busInput =  DataBus;
	end	
	
end
end

endmodule