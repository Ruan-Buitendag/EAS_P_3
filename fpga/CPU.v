module CPU(
	input [7:0] WriteToMemory,
	output [7:0] ReadFromMemory,
	input [3:0] BootLoadAddress,
	
	input clk,
	input slowclk,
	input BootLoad,
	
	output [7:0] D0, 
	output [7:0] IR,
	output [7:0] PC,	
	output [8:15] LSBs
	

);

wire [7:0] DataBus;
wire [15:0] ControlSignals;

wire [7:0] IRtoCU;
wire [7:0] D0toALU;
wire [4:0] MARtoMemory;
wire [8:15] LSBsFromMemory;

wire [7:0] PCTOOut;

assign D0 = D0toALU;
assign IR = IRtoCU;
assign PC = PCTOOut;

assign LSBs = LSBsFromMemory;

CU ControlUnit(
	.ControlSignals(ControlSignals), 
	.nextInstruction(IRtoCU),
	
	.slowclk(slowclk), 
	.Bootload(BootLoad),
	
	.states(state),
	.mc(mc)
);

ALU ArithmeticLogicUnit(
	.ControlSignals(ControlSignals),
	.DataBus(DataBus),
	
	.Data0(D0toALU),
	
	.clk(clk),
	.reset(BootLoad)
);

D0 DataRegister(
	.ControlSignals(ControlSignals),
	.DataBus(DataBus),
	
	.DataToALU(D0toALU),
	
	.clk(clk),
	.reset(BootLoad)
);

IR InstructionRegister(
	.ControlSignals(ControlSignals),
	.DataBus(DataBus),
	
	.IRtoCU(IRtoCU),
	
	.clk(clk),
	.reset(BootLoad)
);

MAR AddressRegister(
	.ControlSignals(ControlSignals),
	.DataBus(DataBus),
	
	.AddressToMemory(MARtoMemory),
	
	.clk(clk),
	.reset(BootLoad)
);

MBR MemoryBufferRegister(
	.ControlSignals(ControlSignals),
	.DataBus(DataBus),
	
	.clk(clk),
	.reset(BootLoad)
);

PC ProgramCounter(
	.ControlSignals(ControlSignals),
	.DataBus(DataBus),
	
	.PCOut(PCTOOut),
	
	.clk(clk),
	.reset(BootLoad)
);



Memory RAM(
	.ControlSignals(ControlSignals),
	.DataBus(DataBus),
	
	.MemoryAddress(MARtoMemory),
	
	.WriteToMemory(WriteToMemory),
	.ReadFromMemory(ReadFromMemory),
	.BootLoadAddress(BootLoadAddress),
	
	.clk(clk),
	.BootLoad(BootLoad),
	
	.LSBs(LSBsFromMemory)

);





endmodule