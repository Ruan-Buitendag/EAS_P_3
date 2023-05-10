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

/* HPS IO */
#define USER_IO_DIR     (0x01000000)
#define BIT_LED         (0x01000000)
#define BUTTON_MASK     (0x02000000)

void startup_display(void)
{
	printf(" _____    _    ____    _  _   _  ___\n"); 
 	printf("| ____|  / \\  / ___|  | || | / |/ _ \\ \n");
 	printf("|  _|   / _ \\ \\___ \\  | || |_| | | | |\n");
 	printf("| |___ / ___ \\ ___) | |__   _| | |_| |\n");
 	printf("|_____/_/   \\_\\____/     |_| |_|\\___/ \n");
	
	printf("------------------------------");
	printf("\n EAS 411 Practical 2 Group 11\n");
	printf("------------------------------\n");
}

void display_confirmation_message(char read_or_write, char full_or_half_word, char msb_or_lsb, uint16_t chip_group, uint16_t sub_chip, uint16_t buffer)
{
	printf("\nYour command is: ");
	if (read_or_write == 'r')
		printf("READ ");
	else
		printf("WRITE ");
	
	if (full_or_half_word == 'f')
		printf("WORD ");
	else
	{
		printf("NIBBLE ");
		if (msb_or_lsb == 'm')
			printf("(MSB) ");
		else
			printf("(LSB) ");
	}
		
	if (read_or_write == 'r')
		printf("from ");
	else
		printf("to ");
	printf("Chip Group %d, ", chip_group);
	printf("Buffer [%d, %d]\n", sub_chip, buffer);

}

uint16_t create_mar_code(char read_or_write, char full_or_half_word, char msb_or_lsb, uint16_t chip, uint16_t buffer)
{
	/*
	|   bit 10   |  bits 9 - 5    |   bits 4 - 2     |       bit 1       |    bit 0   |
	| read/write | chip selection | buffer selection | full or half word | msb or lsb |

	*/
	uint16_t mar_code = 0;
	uint16_t read_write_bit = 0, chip_selection = 0, buffer_selection = 0, full_half_bit = 0, msb_lsb_bit = 0;
	/* If a write was requested, bit 11 would be 1 */
	if (read_or_write == 'w')
		read_write_bit = (1<<10);
	

	chip_selection = (uint16_t)(chip << 5);
	buffer_selection = (uint16_t)(buffer << 2);
	
	if (full_or_half_word == 'h')
		full_half_bit = (1<<1);
	
	if (msb_or_lsb == 'm')
		msb_lsb_bit = 1;
	
	mar_code = read_write_bit | chip_selection | buffer_selection | full_half_bit | msb_lsb_bit;

	return mar_code;
}

int main() {

	void *virtual_base;
	int fd;

	/* FPGA GPIO addresses */
	void *fpga_keys_address;
	
	/* FPGA MAR and MBR addresses*/
	void *fpga_mar_address, *fpga_mbr_address;

	/* HPS GPIO Addresses */
	void *hps_key_address;
	
	/* HPS GPIO direction address */
	void *hps_gpio_direction_address;

	/* HPS input value */
	uint32_t  hps_key_input;

	/* FPGA input values */
	uint32_t  fpga_keys_input;

	/* User Input values */
	char read_write_input = 'r', half_full_input  = 'f', most_least_input = 'l';
	
	/* Memory Write values */
	char write_input[5]  = "0000";
	uint8_t mbr_value = 0;
	uint16_t mar_value = 0;
	
	/* Memory location and chip selection values*/
	int memory_location_input;
	uint8_t chip_selection, buffer_selection, chip_group, sub_chip;
	
	char* binary_lookup[16] = {"0000","0001","0010","0011","0100","0101","0110","0111","1000","1001","1010","1011","1100","1011","1110","1111"};
	

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
	fpga_keys_address   = virtual_base + ( ( unsigned long )( ALT_LWFPGASLVS_OFST + BUTTON_PIO_BASE )  & ( unsigned long )( HW_REGS_MASK ) );
	fpga_mar_address    = virtual_base + ( ( unsigned long )( ALT_LWFPGASLVS_OFST + MAR_PIO_BASE )     & ( unsigned long )( HW_REGS_MASK ) );
	fpga_mbr_address    = virtual_base + ( ( unsigned long )( ALT_LWFPGASLVS_OFST + MBR_PIO_BASE )     & ( unsigned long )( HW_REGS_MASK ) );
	
	/* Retreiving the hps PIO addresses from soc_cv_av/socal/hps.h */
	hps_gpio_direction_address 	= virtual_base + ( ( uint32_t )( ALT_GPIO1_SWPORTA_DDR_ADDR ) & ( uint32_t )( HW_REGS_MASK ) );
	hps_key_address 			= virtual_base + ( ( uint32_t )( ALT_GPIO1_EXT_PORTA_ADDR )   & ( uint32_t )( HW_REGS_MASK ) );
	
	/* Startup Display */
	startup_display();
	
	/* Setting up the direction of the HPS GPIO pins: LED->OUTPUT & KEY->INPUT */ 
	alt_setbits_word( hps_gpio_direction_address , USER_IO_DIR );	
	
	/* Main loop */
	while( 1 ) 
	{
		/* Wait for the HPS button to be pressed by the user */
		printf("\n\t\tPRESS THE HPS KEY TO PERFORM A READ/WRITE!\n");
		hps_key_input 	= alt_read_word( hps_key_address );
		while (!(~hps_key_input & BUTTON_MASK))
		{
			hps_key_input 	= alt_read_word( hps_key_address );
		}
		
		/* Begin line of questioning */
		while (1)
		{
			printf("\nRead or write (r/w)? ");
			scanf(" %c", &read_write_input);
			if (read_write_input == 'r' || read_write_input == 'w')
				break;
		}
		while(1)
		{
			printf("Half or full word access (h/f)? ");
			scanf(" %c", &half_full_input);
			if (half_full_input == 'h' || half_full_input == 'f')
				break;
		}
		if (half_full_input == 'h')
		{
			while (1)
			{
				printf("MSB or LSB (m/l)? ");
				scanf(" %c", &most_least_input);
				if (most_least_input == 'm' || most_least_input == 'l')
					break;
			}
		}
		
		while (1)
		{
			printf("Enter the memory location (0-255): ");
			scanf(" %d", &memory_location_input);
			if (memory_location_input >=0 && memory_location_input < 256)
				break;
		}
		
		/* Determine which chip and buffer the memory location belongs to */
		chip_selection   = (uint8_t)((memory_location_input / 8));
		chip_group       = (uint8_t)((chip_selection / 8));
		sub_chip		 = (uint8_t)((chip_selection % 8));
		buffer_selection = (uint8_t)((memory_location_input % 8));

		/* Display the user input */
		display_confirmation_message(read_write_input, half_full_input, most_least_input, chip_group + 1, sub_chip + 1, buffer_selection + 1);

		/* Wait 1 second */
		usleep(1000*1000);

		printf("\n\t\tPRESS THE FPGA KEY 1 TO CONFIRM INPUT\n");
		fpga_keys_input = (~alt_read_word( fpga_keys_address ) & 0x2) >> 1;
		
		while (!fpga_keys_input) 
		{
			fpga_keys_input = (~alt_read_word( fpga_keys_address ) & 0x2) >> 1;
		}

		/* Creating a MAR code for reading the position currently stored in the requested memory address */
		mar_value = create_mar_code('r', half_full_input, most_least_input, chip_selection, buffer_selection);
		
		*(uint32_t *)fpga_mar_address = mar_value;
		
		/* Reading the value currently stored in the requested memory address out of the MBR address */
		mbr_value = alt_read_word( fpga_mbr_address );

		if (half_full_input == 'h')
		{
			printf("\nCurrent value in Chip Group %d, Buffer [%d, %d]:  %s\n", chip_group + 1, sub_chip + 1, buffer_selection + 1, binary_lookup[mbr_value]);
		}
		else
		{
			printf("\nCurrent value in Chip Group %d, Buffer [%d, %d]:  %c\n", chip_group + 1, sub_chip + 1, buffer_selection + 1, mbr_value);
		}
		/* Wait 1 second */
		usleep(1000*1000);

		/* If a write was requested */
		if (read_write_input == 'w')
		{
			/* Create the MAR code to write to the inputted memory location */
			mar_value = create_mar_code('w', half_full_input, most_least_input, chip_selection, buffer_selection);
			
			/* Request data from the user to be written into memory */
			if (half_full_input == 'h')
			{
				printf("Input 4 digit binary value: ");
				scanf("%4s", write_input);
				mbr_value = (uint8_t)(strtol(write_input, NULL, 2) & 0xF);
			}
			else
			{
				printf("Input lowercase ASCII characters only [a..z]: ");
				scanf(" %c", write_input);	
				mbr_value = (uint8_t)write_input[0];
			}
			
			/* Set the MAR register (Wire) to indicate a write */
			*(uint32_t *)fpga_mar_address = mar_value;

			/* Set the MBR buffer (wire) to the user input value to be written */
			*(uint32_t *)fpga_mbr_address = mbr_value;
			
		}

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

