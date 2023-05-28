module Memory(
	input [15:0] ControlSignals,	
	inout [7:0] DataBus,
	input [3:0] MemoryAddress,

	input [7:0] WriteToMemory,
	output [7:0] ReadFromMemory,
	input [3:0] BootLoadAddress,
	
	input clk,
	input BootLoad, 
	
	output [8:15] LSBs

);



reg [7:0] MemoryArray[0:15];

reg [7:0] tempBusOutput;
reg [7:0] tempHPSOutput;

assign ReadFromMemory = tempHPSOutput;

assign LSBs = tempLSBs;


reg [7:0] tempLSBs;

integer i;

always @(*) begin
 for (i = 8; i <= 15; i = i + 1)
	tempLSBs[i-8] = MemoryArray[i][0];
end



assign DataBus = (ControlSignals[7] && !BootLoad) ? tempBusOutput : 1'bz;

always @(posedge(clk))
begin
	if(BootLoad) begin
		MemoryArray[BootLoadAddress] = WriteToMemory;
		tempHPSOutput = MemoryArray[BootLoadAddress[2:0]];
		
		MemoryArray[8] = 0;
		MemoryArray[9] = 0;
		MemoryArray[10] = 0;
		MemoryArray[11] = 0;
		MemoryArray[12] = 0;
		MemoryArray[13] = 0;
		MemoryArray[14] = 0;
		MemoryArray[15] = 0;
		
		tempBusOutput = 0;
		
	end
	else begin
		tempHPSOutput = MemoryArray[BootLoadAddress];
	
		if(ControlSignals[14]) begin
			MemoryArray[MemoryAddress] = DataBus;
		end
		else		
		if(ControlSignals[15]) begin
			tempBusOutput = MemoryArray[MemoryAddress];
		end
		
	end
end

endmodule