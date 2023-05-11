module Memory(

	input [7:0] WriteToMemory,
	output [7:0] ReadFromMemory,
	input [4:0] Address,
	input ReadOrWrite, //1 for write
	input clk

);

reg [7:0] MemoryArray[0:15];

reg [7:0] tempOutput;

assign ReadFromMemory = tempOutput;

always @(posedge(clk))
begin

	if(ReadOrWrite) begin
		MemoryArray[Address] = WriteToMemory;
		tempOutput = WriteToMemory;
	end
	else begin
		tempOutput = MemoryArray[Address];
	end

end

endmodule