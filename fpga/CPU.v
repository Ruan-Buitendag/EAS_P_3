module CPU(
	input [7:0] WriteToMemory,
	output [7:0] ReadFromMemory,
	input [3:0] BootLoadAddress,
	
	input clk,
	input BootLoad,
	
	output [7:0] bus, 
	output [15:0] cs, 
	output [2:0] state,
	output [2:0] mc,
	output [7:0] IRs,
	output [7:0] D0
	
	

);

wire [7:0] DataBus;
wire [15:0] ControlSignals;
wire [7:0] IRtoCU;
wire [7:0] D0toALU;
wire [4:0] MARtoMemory;

wire slowclock;

assign bus = DataBus;
assign cs = ControlSignals;
assign IRs = IRtoCU;
assign D0 = D0toALU;

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
	.BootLoad(BootLoad)

);

ClockDivider d(
	.clk(clk),
	.clk_out(slowclock)
);



endmodule