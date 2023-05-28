module CU(
	output [15:0] ControlSignals,	
		
	input [7:0] nextInstruction, 	// connected to IR
		
	input slowclk,
	input Bootload, 
	
	output [2:0] states,
	output [2:0] mc

	
);

parameter FETCH = 0;
parameter LDA = 1;
parameter STA = 2;
parameter ADD = 3;
parameter SUB = 4;
parameter BRA = 5;
 

assign ControlSignals = ControlSignalOutput;

reg [15:0] ControlSignalOutput;

reg [2:0] microinstructionCounter;

reg [2:0] state;

assign states = state;
assign mc = microinstructionCounter;

initial begin
	microinstructionCounter = 0;
	state = FETCH;
end


always @(posedge(slowclk))
begin
if(!Bootload) begin

	if(state == FETCH) begin		 				// fetch
		ControlSignalOutput = 16'b0;

		case (microinstructionCounter)
			0: begin										// Pc into MAR
				
				ControlSignalOutput[4] = 1'b1;	// EPC
				ControlSignalOutput[13] = 1'b1;	// CMAR		
				microinstructionCounter = microinstructionCounter + 1;	
			
			end
			
			1: begin										// Memory into MBR
				
				ControlSignalOutput[15] = 1'b1;	// R
				ControlSignalOutput[7] = 1'b1;	// EMSR		
				ControlSignalOutput[12] = 1'b1;	// CBR	
				microinstructionCounter = microinstructionCounter + 1;	
			
			
			end
			
			2: begin										// MBR into IR
				
				ControlSignalOutput[6] = 1'b1;	// EMBR		
				ControlSignalOutput[10] = 1'b1;	// CIR	
				microinstructionCounter = microinstructionCounter + 1;	
			
			end
			
			
			3: begin										// Increment PC
				
				ControlSignalOutput[4] = 1'b1;	// EPC
				ControlSignalOutput[1:0] = 2'b10;	// FF	
				ControlSignalOutput[8] = 1'b1;	// CALU	
				microinstructionCounter = microinstructionCounter + 1;	
			
			
			end
			
			
			4: begin										// ALU into PC
				
				ControlSignalOutput[2] = 1'b1;	// EALU
				ControlSignalOutput[11] = 1'b1;	// CPC	
				microinstructionCounter = 0;
				
				case (nextInstruction[7:5])
					3'b000: begin
						state = LDA;
					end
					3'b001: begin
						state = STA;
					end
					3'b010: begin
						state = ADD;
					end
					3'b011: begin
						state = SUB;
					end
					3'b100: begin
						state = BRA;
					end
				endcase									// end next instruction case

		
			end									
		endcase											// end fetch case			
	end													// end fetch

		
	
	else if(state == LDA) begin

		ControlSignalOutput = 16'b0;

		if(nextInstruction[4] == 1'b1) begin  // literal addressing
			
			ControlSignalOutput[5] = 1'b1; 		// EIR
			ControlSignalOutput[9] = 1'b1;		// CD0	
			microinstructionCounter = 0;
			state = FETCH;
		
		end
		else begin										// absolute addressing
			case (microinstructionCounter)
				0: begin										// IR into MAR
					
					ControlSignalOutput[5] = 1'b1;	// EIR
					ControlSignalOutput[13] = 1'b1;	// CMAR		
					microinstructionCounter	= microinstructionCounter + 1;		
				
				end
			
				1: begin										// Memory into MBR
					
					ControlSignalOutput[15] = 1'b1;	// R
					ControlSignalOutput[7] = 1'b1;	// EMSR		
					ControlSignalOutput[12] = 1'b1;	// CBR	
					microinstructionCounter	= microinstructionCounter + 1;	
				
				
				end			

			
				2: begin										// MBR into D0
					
					ControlSignalOutput[6] = 1'b1;	// EMBR
					ControlSignalOutput[9] = 1'b1;	// CD0	
					microinstructionCounter = 0;
					state = FETCH;
					
				end			
			
			endcase									
		
		end												// end absolute addressing
			
	end													// end LDA
	
	
	else if (state == STA) begin
		ControlSignalOutput = 16'b0;
		
		case (microinstructionCounter)
			0: begin										// IR into MAR
				
				ControlSignalOutput[5] = 1'b1;	// EIR
				ControlSignalOutput[13] = 1'b1;	// CMAR		
				microinstructionCounter	= microinstructionCounter + 1;		
			
			end
		
			1: begin										// D0 into MBR
				
				ControlSignalOutput[3] = 1'b1;	// ED0		
				ControlSignalOutput[12] = 1'b1;	// CBR	
				microinstructionCounter	= microinstructionCounter + 1;	
			
			end			

		
			2: begin										// MBR into Memory
				
				ControlSignalOutput[6] = 1'b1;	// EMBR
				ControlSignalOutput[14] = 1'b1;	// W	
				microinstructionCounter = 0;
				state = FETCH;
				
			end			
			
		endcase	
		
	
	end // end STA
	
	else if (state == ADD) begin
		ControlSignalOutput = 16'b0;
	
		if (nextInstruction[4] == 1)  begin // literal
			
			case (microinstructionCounter)
				0: begin										// IR into ALU
					
					ControlSignalOutput[5] = 1'b1;	// EIR
					ControlSignalOutput[8] = 1'b1;	// CALU						
					microinstructionCounter	= microinstructionCounter + 1;		
				
				end		

			
				1: begin										// ALU into D0
					
					ControlSignalOutput[2] = 1'b1;	// EALU
					ControlSignalOutput[9] = 1'b1;	// CD0	
					microinstructionCounter = 0;
					state = FETCH;
					
				end		
			
			endcase	
			
			
		end
		else begin			// absolute
	
			case (microinstructionCounter)
				0: begin										// IR into MAR
					
					ControlSignalOutput[5] = 1'b1;	// EIR
					ControlSignalOutput[13] = 1'b1;	// CMAR		
					microinstructionCounter	= microinstructionCounter + 1;		
				
				end
			
				1: begin										// Memory into MBR
					
					ControlSignalOutput[15] = 1'b1;	// R
					ControlSignalOutput[7] = 1'b1;	// EMSR		
					ControlSignalOutput[12] = 1'b1;	// CBR	
					microinstructionCounter	= microinstructionCounter + 1;	
				
				
				end			

			
				2: begin										// MBR into ALU
					
					ControlSignalOutput[6] = 1'b1;	// EMBR
					ControlSignalOutput[8] = 1'b1;	// CALU	
					ControlSignalOutput[1:0] = 2'b00;	// FF	
					microinstructionCounter	= microinstructionCounter + 1;	
					
				end		
			
				3: begin										// ALU into D0
					
					ControlSignalOutput[2] = 1'b1;	// EALU
					ControlSignalOutput[9] = 1'b1;	// CD0	
					microinstructionCounter = 0;
					state = FETCH;
					
				end		
			
			endcase	
		end	
	
	
	end // end ADD
	
	else if (state == SUB) begin
		ControlSignalOutput = 16'b0;
	
		if (nextInstruction[4] == 1)  begin // literal
			
			case (microinstructionCounter)
				0: begin										// IR into ALU
					
					ControlSignalOutput[5] = 1'b1;	// EIR
					ControlSignalOutput[8] = 1'b1;	// CALU	
					ControlSignalOutput[0] = 1'b1;	// F0						
					microinstructionCounter	= microinstructionCounter + 1;		
				
				end		

			
				1: begin										// ALU into D0
					
					ControlSignalOutput[2] = 1'b1;	// EALU
					ControlSignalOutput[9] = 1'b1;	// CD0	
					microinstructionCounter = 0;
					state = FETCH;
					
				end		
			
			endcase	
			
			
		end
		else begin			// absolute
	
			case (microinstructionCounter)
				0: begin										// IR into MAR
					
					ControlSignalOutput[5] = 1'b1;	// EIR
					ControlSignalOutput[13] = 1'b1;	// CMAR		
					microinstructionCounter	= microinstructionCounter + 1;		
				
				end
			
				1: begin										// Memory into MBR
					
					ControlSignalOutput[15] = 1'b1;	// R
					ControlSignalOutput[7] = 1'b1;	// EMSR		
					ControlSignalOutput[12] = 1'b1;	// CBR	
					microinstructionCounter	= microinstructionCounter + 1;	
				
				
				end			

			
				2: begin										// MBR into ALU
					
					ControlSignalOutput[6] = 1'b1;	// EMBR
					ControlSignalOutput[8] = 1'b1;	// CALU	
					ControlSignalOutput[1:0] = 2'b01;	// FF	
					microinstructionCounter	= microinstructionCounter + 1;	
					
				end		
			
				3: begin										// ALU into D0
					
					ControlSignalOutput[2] = 1'b1;	// EALU
					ControlSignalOutput[9] = 1'b1;	// CD0	
					microinstructionCounter = 0;
					state = FETCH;
					
				end		
			
			endcase	
		end	
	
	
	end // end SUB
	
	else if (state == BRA) begin
		ControlSignalOutput = 16'b0;
		
		ControlSignalOutput[5] = 1'b1;		// EIR
		ControlSignalOutput[11] = 1'b1;		// CPC
		
		microinstructionCounter = 0;
		state = FETCH;
			
	end														
					
end
else begin  // if bootloading

	state = FETCH;
	microinstructionCounter = 0;
	ControlSignalOutput = 16'b0;	
end

end

endmodule