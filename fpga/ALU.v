module ALU(
	input [15:0] ControlSignals,	
	inout [7:0] DataBus,
	
	input [7:0] Data0,
	
	input clk, 
	input reset
	
);

reg [7:0] busInput;
reg [7:0] tempOutput;

assign DataBus = (ControlSignals[2]) ? tempOutput : 1'bz;

always @(posedge(clk))
begin
if (reset) begin
		busInput = 0;
		tempOutput = 0;
end
else 
begin

	if(ControlSignals[8]) begin // Calu
		busInput =  DataBus;
		
		if(ControlSignals[1:0] == 2'b00) begin // add
			tempOutput = Data0 + busInput;
		end
		else if(ControlSignals[1:0] == 2'b01) begin // subract
			tempOutput = Data0 - busInput;
		end
		else if(ControlSignals[1:0] == 2'b10) begin // increment
			tempOutput = busInput + 1;
		end
		else if(ControlSignals[1:0] == 2'b11) begin // decrement
			tempOutput = busInput - 1;
		end
	end	
end
end

endmodule