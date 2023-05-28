#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "hwlib.h"
#include "soc_cv_av/socal/socal.h"
#include "soc_cv_av/socal/hps.h"
#include "soc_cv_av/socal/alt_gpio.h"
#include "hps_0.h"
#include <stdlib.h>
#include <string.h>


/* HPS Register address */
#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

char instruction_set[5][4] = {"LDA", "STA", "ADD", "SUB", "BRA"};

typedef enum
{
	FALSE,
	TRUE
} boolean_t;

void startup_display(void)
{
	printf("\n");
	printf("  /$$    /$$  /$$$$$$         /$$$$$$                  /$$          \n");
	printf(" | $$   | $$ /$$__  $$       /$$__  $$                | $$          \n");
	printf(" | $$   | $$| $$  \\__/      | $$  \\__/  /$$$$$$   /$$$$$$$  /$$$$$$ \n");
	printf(" |  $$ / $$/|  $$$$$$       | $$       /$$__  $$ /$$__  $$ /$$__  $$\n");
	printf("  \\  $$ $$/  \\____  $$      | $$      | $$  \\ $$| $$  | $$| $$$$$$$$\n");
	printf("   \\  $$$/   /$$  \\ $$      | $$    $$| $$  | $$| $$  | $$| $$_____/\n");
	printf("    \\  $/   |  $$$$$$/      |  $$$$$$/|  $$$$$$/|  $$$$$$$|  $$$$$$$\n");
	printf("     \\_/     \\______/        \\______/  \\______/  \\_______/ \\_______/\n");
    printf("\n\tVersion 0.0\n");                                         
	
}


uint16_t create_instruction(uint16_t memory_location, char* user_instruction )
{
	/*
	|    bits 10 - 8      |      bits 7 - 5     |      bit 4      | bits 3 - 0 |
	|   Memory Location   |    Operation code   | Addressing Mode |   Operand  |
	*/

	/* The input is validated by "syntax_checker" and therefore assumed to be correct */
	uint16_t instruction = 0x0000;

	/* Shift the given memory location into bits 8 to 10*/
	instruction |= (memory_location << 8);

	/* Retrieve op code value and shift that to bits 5 - 7 */
	char op_code[4];

	int i;
	for (i = 0; i < 3; i++)
		op_code[i] = user_instruction[i];
	
	op_code[3] = '\0';

	int check_op_code;
	for (i = 0; i < 5; i++)
	{
		check_op_code = strcmp(op_code, instruction_set[i]);
		if (check_op_code == 0)
			break;
	}

	instruction |= (i << 5);

	/* Shift the addressing mode into bits 4 */
	uint8_t number_index;
	if (user_instruction[4] == '$')
	{
		instruction |= (1 << 4);
		number_index = 5;
	}
	else
	{
		number_index = 4;
	}
	
	uint8_t operand = atoi(&user_instruction[number_index]);

	instruction |= operand;

	return instruction;
}

boolean_t syntax_checker(char * user_instruction)
{
	
	uint8_t input_length = strlen(user_instruction);
	if (input_length < 5)
	{
		printf("| ERROR: Invalid Instruction Length\n");
		return FALSE;
	}

	/* Check if the inputted op code is valid */
	char op_code[4];

	int i;
	for (i = 0; i < 3; i++)
		op_code[i] = user_instruction[i];
	
	op_code[3] = '\0';

	int check_op_code;
	for (i = 0; i < 5; i++)
	{
		check_op_code = strcmp(op_code, instruction_set[i]);
		if (check_op_code == 0)
			break;	
	}

	if (check_op_code != 0)
		{
			printf("| ERROR: %s is not an op code\n", op_code);
			return FALSE;
		} 

	if (user_instruction[3] != ' ')
	{
		printf("| ERROR: Ensure there is a SPACE after the Op Code\n");
		return FALSE;
	}

	uint8_t number_index;
	/* If Absolute Addressing was inputted */
	if (user_instruction[4] != '$')
	{
		/* Check if the character inputted is a number between 0-9 */
		if (((uint8_t)user_instruction[4] < 48) || ((uint8_t)user_instruction[4] > 57))
		{
			/* If the character was not a number, then the addressing mode symbol was incorrect*/
			printf("| ERROR: Character \'%c\' is not an addressing mode specifier\n", user_instruction[4]);
			return FALSE;
		}
		number_index = 4;
	}
	else
	{
		number_index = 5;		
	}

	uint8_t input_operand = atoi(&user_instruction[number_index]);
	if (input_operand > 15 )
	{
		printf("| ERROR: Ensure that the value you inputted is between 0 and 15\n");
		return FALSE;
	}
	
	return TRUE;
}

void print_binary(int value, int line)
{
	if (value == 0) {
        printf("0\n");
        return;
    }
   
   	// Stores binary representation of number.
   	uint8_t binaryNum[11] = {0}; // Assuming 32 bit integer.
   	int i;
   
   	for (i=0 ;value > 0; i++)
	{
      binaryNum[i] = value % 2;
      value /= 2;
   	}
   
   // Printing array in reverse order.
   printf("%d: ", line);
   int j = 0;
   for (j = 10; j >= 0; j--)
   {
		if (j == 7 || j == 4 || j == 3)
			printf(" ");
      printf("%d", binaryNum[j]);
   }
	
	printf("\n");
}

int main() {

	void *virtual_base;
	int fd;
	
	/* FPGA MAR and MBR addresses*/
	void *fpga_boot_loader_address, *fpga_instruction_address;

	char user_input[8][8], input_character;

	uint16_t instructions[8];

	
	/* Memory Mapping using the Sotware API  */ 
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) 
	{
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}

	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

	/* Incase the memory mapping fails */
	if( virtual_base == MAP_FAILED ) 
	{
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return( 1 );
	}
	
	/* Retreiving the fpga PIO addresses from hps_0.h */
	fpga_boot_loader_address   = virtual_base + ( ( unsigned long )( ALT_LWFPGASLVS_OFST + BOOT_LOADER_BASE )  & ( unsigned long )( HW_REGS_MASK ) );
	fpga_instruction_address   = virtual_base + ( ( unsigned long )( ALT_LWFPGASLVS_OFST + INSTRUCTION_BASE )  & ( unsigned long )( HW_REGS_MASK ) );
	
	/* Startup Display */
	startup_display();
	
	/* Main loop */
	while( 1 ) 
	{
		/* Set the Bootloader Flag low to indicate that a program is being loaded */
		*(uint32_t *)fpga_boot_loader_address = 0x0;

		printf(" _______\n");                                    
		printf("|Prac3.s|___________________________________________________________\n");
		printf("| \n");
		

		
		uint8_t instruction_counter, instruction_characters;
		boolean_t correct_syntax;

		for (instruction_counter = 0; instruction_counter < 8; instruction_counter++)
		{
			/* Create sudo line numbering for the "IDE" */
			printf("|   %d\t ", instruction_counter + 1);
			
			/* A blank line indicates the end of the program */
			input_character = getchar ();
			if (input_character == '\n')
				break;

			/* For input instruction of variable size, each character is read and saved individually*/
			instruction_characters = 0;
			
			while(input_character != '\n')
			{
				if ((uint8_t)input_character > 31)
				{
					user_input[instruction_counter][instruction_characters] = input_character;
					instruction_characters++;
				}
				input_character = getchar();
			}

			user_input[instruction_counter][instruction_characters] ='\0';
			
			/* Check in inputted instruction is valid */
			correct_syntax = syntax_checker(user_input[instruction_counter]);

			/* If the syntax is incorrect, give the user another chance to input */
			if (correct_syntax == FALSE)
			{
				instruction_counter--;
			}
			else 
			{
				instructions[instruction_counter] = create_instruction(instruction_counter, user_input[instruction_counter]);
			}	
		}
		printf("|___________________________________________________________________\n");
		
		
		/* Input the Instructions directly into the program memory */
		int i;
		for (i = 0; i < instruction_counter; i++)
		{
			*(uint32_t *)fpga_instruction_address = instructions[i];
			usleep(1000);
		}
		
		/* Set the Bootloader Flag High to indicate that a program is being loaded */
		*(uint32_t *)fpga_boot_loader_address = 0x1;
		
		printf("\n\t\t\tAssembler Complete\n\n");
		printf(" --------------------------------------------------------------------------\n");
		printf("|    bits 10 - 8      |      bits 7 - 5     |      bit 4      | bits 3 - 0 |\n");
		printf("|   Memory Location   |    Operation code   | Addressing Mode |   Operand  |\n");
		printf(" --------------------------------------------------------------------------\n");
		for (i = 0; i < instruction_counter; i++)
		{
			print_binary(instructions[i], i+1);
		}
		
		break;

	}
	
	/* Clean up memory mapping and exit */
	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	close( fd );

	return( 0 );
}

