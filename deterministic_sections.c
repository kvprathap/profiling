#include <unistd.h>
#include <fcntl.h>
#include<stdio.h>
#include<sys/mman.h>

static char bss_array[1024];
/* Initializing atleast first few bytes to make sure
 * this goes to .data section
 */
char data_array[1024] = {1, 2, 3, 4};
int main(int argc, char *argv[])
{
	int opt;
	char stack_array[1024];
	int i;
	while ((opt = getopt(argc, argv, "sbd")) != -1) {
		switch (opt) {
		case 's': /* .stack */
			printf("accesssing .stack\n");
			for (i = 0; i < 1024; i++)
				stack_array[i] = i;
			break;
		case 'b': /* .bss */
			printf("accesssing .bss\n");
			for (i = 0; i < 1024; i++)
				bss_array[i] = i;
			break;
		case 'd': /* data */
			printf("accesssing .data\n");
			for (i = 0; i < 1024; i++)
				data_array[i] = i;
			break;
		default: /* access all */
			for (i = 0; i < 1024; i++) {
				bss_array[i] = i;
				data_array[i] = i;
				stack_array[i] = i;
			}
			break;
		}
	}
	return 0;
}
