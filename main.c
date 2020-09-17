#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

uint8_t MCSAVE[8192];
uint16_t POS = 0x0000;
uint16_t BASEPOS = 0x0000;
uint8_t FRAME = 0x00;
uint8_t ICONS = 0x00;
uint8_t MCS_CHECKSUM = 0x00;

char *SAVEFILE;

#define RAW_SAVE 8192 //bytes
#define MCS_SAVE 8320 //bytes

#define TYPE_RAW 1
#define TYPE_MCR 2

uint8_t TYPE = 0;

void print_frame_header()
{
	printf("\n[0x%04X] Frame: %d\n", POS, FRAME);
	printf("------------------------------------------------------------\n");
}

int main(int argc, char *argv[])
{
	if (argc <= 1 || argc > 2 || argv[1] == NULL) {
		printf("  usage: %s [SAVE]\n", argv[0]);
		exit(EXIT_FAILURE);
	}
	else {
		SAVEFILE = argv[1];
	}

	memset(MCSAVE, 0x00, sizeof(MCSAVE));

	FILE *file;
	file = fopen(SAVEFILE, "rb");
	if (file == NULL) {
		printf("Couldn't open file: %s (%s)\n", SAVEFILE, strerror(errno));
		exit(EXIT_FAILURE);
	}

	// get file size
	fseek(file, 0, SEEK_END);

	if (ftell(file) == RAW_SAVE) {
		printf("PSX raw save (%ld bytes)\n", ftell(file));
		TYPE = TYPE_RAW;
	}
	else if (ftell(file) == MCS_SAVE) {
		printf("PSX mcs save (%ld bytes)\n", ftell(file));
		TYPE = TYPE_MCR;
	}
	else {
		printf("Unknown or Invalid PSX save file\n");
		fclose(file); /* release file */
		exit(EXIT_FAILURE);
	}

	/* return to the beginning of file */
	fseek(file, 0, SEEK_SET);

		/* copy file into buffer */
	if (fread(MCSAVE, 1, 8192, file) == 0) {
		printf("Error: Mapping failed (%s: %s)\n", file, strerror(errno));
		fclose(file); /* release file */
		exit(EXIT_FAILURE);
	}

	fclose(file); /* release file */

	if (TYPE == TYPE_MCR) {
		print_frame_header();
		printf("[0x%04X] MCS Header: %c\n", POS, MCSAVE[POS]);
		POS += 4;
		printf("[0x%04X] Blocks: 0x%02X%02X%02X\n", POS, MCSAVE[POS], MCSAVE[POS + 1], MCSAVE[POS + 2], MCSAVE[POS + 3]);
		POS += 4;
		printf("[0x%04X] Link: 0x%02X%02X\n", POS, MCSAVE[POS], MCSAVE[POS + 1]);
		POS += 2;
		printf("[0x%04X] Region Code: %c%c\n", POS, MCSAVE[POS], MCSAVE[POS + 1]);
		POS += 2;
		printf("[0x%04X] Product Code: ", POS);
		for (; POS < 0x16; POS ++) {
			printf("%c", MCSAVE[POS]);
		}
		printf("\n");
		printf("[0x%04X] Identifier: ", POS);
		for (; POS < 0x1E; POS ++) {
			printf("%c", MCSAVE[POS]);
		}
		printf("\n");
		printf("[0x%04X] Padding: (should be 0x00) ", POS);
		for (; POS < 0x7F; POS ++) {
			if (MCSAVE[POS] == 0x00) {
				//do nothing
			}
			else
				printf("!%02X!", MCSAVE[POS]);
		}
		printf("\n");
		printf("[0x%04X] XOR Checksum: 0x%02X (", POS, MCSAVE[POS]);
		POS ++;
		BASEPOS = 128;
	}

	//calculate mcs xor checksum
	POS = 0x0000;
	for (; POS < 128; POS ++) {
		MCS_CHECKSUM ^= POS;
	}
	if (MCS_CHECKSUM == 0x00)
		printf("Passed check)\n");
	else
		printf("Failed check)\n");

	FRAME ++;

	print_frame_header();
	printf("[0x%04X] Header: ", POS);
	printf("%c%c\n", MCSAVE[POS], MCSAVE[POS + 1]);
	POS += 2;

	printf("[0x%04X] Icon Type: ", POS);
	switch (MCSAVE[POS]) {
		case 0x00:
			printf("%d (no icon)\n", MCSAVE[POS]);
			ICONS = 0;
			break;
		case 0x11:
			printf("%d (static, one frame)\n", MCSAVE[POS]);
			ICONS = 1;
			break;
		case 0x12:
			printf("%d (animated, two frames)\n", MCSAVE[POS]);
			ICONS = 2;
			break;
		case 0x13:
			printf("%d (animated, three frames)\n", MCSAVE[POS]);
			ICONS = 3;
			break;
		default:
			break;
	}
	POS ++;

	printf("[0x%04X] Blocks Used: ", POS);
	printf("%d\n", MCSAVE[POS]);
	POS ++;

	printf("[0x%04X] Title: ", POS); //16 bit values
	uint8_t k = 0;
	for (; POS < (BASEPOS + 68); POS ++) {
		switch (MCSAVE[POS]) {
		case 0x00: //skip null
		case 0x81: //fallthrough
			POS ++; //skip we only need the lower byte for english
			if (MCSAVE[POS] == 0x40) { //space
				printf(" ");
			}
			else if (MCSAVE[POS] >= 0x69 && MCSAVE[POS] <= 0x6A) { // ( and )
				printf("%c", MCSAVE[POS] - 0x41);
			}
			else if (MCSAVE[POS] == 0x5E) { // /
				printf("%c", MCSAVE[POS] - 0x2F);
			}
			else if (MCSAVE[POS] == 0x93) { // %
				printf("%c", MCSAVE[POS] - 0x6E);
			}
			else if (MCSAVE[POS] == 0x7C) { // -
				printf("%c", MCSAVE[POS] - 0x4F);
			}
			else if (MCSAVE[POS] == 0x44) { // .
				printf("%c", MCSAVE[POS] - 0x16);
			}
			else if (MCSAVE[POS] == 0x46) { // :
				printf("%c", MCSAVE[POS] - 0x0C);
			}
			else if (MCSAVE[POS] == 0x66) { // '
				printf("%c", MCSAVE[POS] - 0x3F);
			}
			else if (MCSAVE[POS] == 0x00) { // null
				break;
			}
			else {
				printf("\n#BUG# Unknown char: 0x81 0x%02X", MCSAVE[POS]);
				break;
			}
			break;
		case 0x82:
			POS ++; //skip we only need the lower byte for english
			if (MCSAVE[POS] >= 0x4F && MCSAVE[POS] <= 0x58) { //0 - 9
				printf("%c", MCSAVE[POS] - 0x1F);
			}
			else if (MCSAVE[POS] >= 0x60 && MCSAVE[POS] <= 0x79) { //A - Z
				printf("%c", MCSAVE[POS] - 0x1F);
			}
			else if (MCSAVE[POS] >= 0x81 && MCSAVE[POS] <= 0x9A) { //a - z
				printf("%c", MCSAVE[POS] - 0x20);
			}
			else if (MCSAVE[POS] == 0x00) { // null
				break;
			}
			else {
				printf("\n#BUG# Unknown char: 0x82 0x%02X", MCSAVE[POS]);
				break;
			}
			break;
		default:
			//printf("\n Unknown char: 0x%02X\n", MCSAVE[POS]);
			break;
		}
	}
	printf("\n");

	printf("[0x%04X] Reserved: (should be 0x00) \n", POS);
	for (; POS < (BASEPOS + 96); POS ++) {
		if (MCSAVE[POS] == 0x00) {
			//do nothing
		}
		else
			printf("Pocket station: %02x\n", MCSAVE[POS]);
	}

	printf("[0x%04X] Icon Colour Palette:\n", POS);
	uint8_t j = 0;
	for (; POS < (BASEPOS + 128); POS ++) {
		printf("%01X(0x%02X%02X) ", j, MCSAVE[POS], MCSAVE[POS + 1]);
		POS ++, j ++;
		if (j == 8)
			printf("\n");
	}

	FRAME ++;
	printf("\n");


	for (uint8_t i = 0; i < ICONS; i++) {
		print_frame_header();
		printf("Icon Data: (HEX) \n");
		uint16_t tmpPOS = POS;
		for (uint8_t i = 0; POS < (tmpPOS + 128); POS ++) {
			//printf("(%d) ", POS);
			i ++;
			printf("%01X %01X ", MCSAVE[POS] & 0x0F, (MCSAVE[POS] >> 4) & 0x0F);
			if (i == 8) {
				printf("\n");
				i = 0;
			}
		}
		FRAME ++;
		tmpPOS += 128;
	}

	uint16_t END_FRAME;
	for (;FRAME <= 64; FRAME ++) {
		END_FRAME = POS + 128;
		print_frame_header();
		printf("Save Data: (HEX) \n");
		for (uint8_t i = 0; POS < END_FRAME; POS ++) {
			//printf("(%d) ", POS);
			printf("%02X ", MCSAVE[POS]);
			i ++;
			if (i == 32) {
				printf("\n");
				i = 0;
			}
		}
	}

}
