/*
 *
 *  Copyright (c) 2006  Warren Jasper <wjasper@tx.ncsu.edu>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <ctype.h>
#include <sys/types.h>
#include <asm/types.h>

#include "pmd.h"
#include "usb-erb.h"

/* Test Program */
int toContinue() 
{
  int answer;
  answer = 0; //answer = getchar();
  printf("Continue [yY]? ");
  while((answer = getchar()) == '\0' ||
	answer == '\n');
  return ( answer == 'y' || answer == 'Y');
}

int main (int argc, char **argv) {
  
  int ch;
  int temp;
  int device = 0;  // either USBERB24 or USBERB08
  __u16 status;
  char serial[9];
  __u8 input; 
  __u8 port;
  __u8 pin = 0;
  __u8 bit_value;

  HIDInterface*  hid = 0x0;
  hid_return ret;
  int interface;


  // Debug information.  Delete when not needed    
  //  hid_set_debug(HID_DEBUG_ALL);
  //  hid_set_debug_stream(stderr);
  //  hid_set_usb_debug(2);

  ret = hid_init();
  if (ret != HID_RET_SUCCESS) {
    fprintf(stderr, "hid_init failed with return code %d\n", ret);
    return -1;
  }

  if ((interface = PMD_Find_Interface(&hid, 0, USBERB24_PID)) >= 0) {
    printf("USB ERB24 Device is found! Interface = %d\n", interface);
    device = USBERB24_PID;
  } else if ((interface = PMD_Find_Interface(&hid, 0, USBERB08_PID)) >= 0) {
    printf("USB ERB08 Device is found! Interface = %d\n", interface);
    device = USBERB08_PID;
    printf("device = %d\n", device);
  } else {
    fprintf(stderr, "USB ERB24 or ERB08 not found.\n");
    exit(-1);
  }

  while(1) {
    printf("\nUSB ERB24 and ERB08 Testing\n");
    printf("----------------\n");
    printf("Hit 'b' to blink LED\n");
    printf("Hit 'd' to test digital I/O \n");
    printf("Hit 'e' to exit\n");
    printf("Hit 'g' to get serial number\n");
    printf("Hit 's' to get status\n");
    printf("Hit 'r' to reset\n");
    printf("Hit 't' to test digital bit I/O\n");
    printf("Hit 'l' to get temperature\n");
    
    while((ch = getchar()) == '\0' || ch == '\n');

    switch(ch) {
    case 'b': /* test to see if led blinks */
      usbBlink_USBERB(hid);
      break;
    case 'd':
      printf("\nTesting Digital I/O \n");
      do {
	if (device == USBERB24_PID) {
	  printf("Enter a port number [0-3]: ");
	  scanf("%hhd", &port);
	  if (port > 3) break;
	  printf("Enter a byte number [0-0xff] : " );
          scanf("%x", &temp);
          usbDOut_USBERB(hid, port, (__u8)temp);
	} else {
	  printf("Enter a port number [2-3]: ");  // only CL and CH on ERB08
	  scanf("%hhd", &port);
	  printf("port = %d\n", port);
	  if (port != 2 &&  port != 3) continue;
          printf("Enter a nibble number [0-0xf] : " );
          scanf("%x", &temp);
	  usbDOut_USBERB(hid, port, (__u8)temp);
	}
        status = usbGetStatus_USBERB(hid);
	input = usbDIn_USBERB(hid, port);
        switch (port) {
          case 0:   /* Port A */
	    printf("    Port A = %#x\n", input);
            if (status & 0x1<<0) {
              printf("    Port A polarity = normal\n");
            } else {
              printf("    Port A polarity = inverted\n");
            }
            if (status & 0x1<<4) {
              printf("    Port A  = pull up\n");
            } else {
              printf("    Port A  = pull down\n");
            }
            break;
          case 1:   /* Port B */
	    printf("    Port B = %#x\n", input);
            if (status & 0x1<<1) {
              printf("    Port B polarity = normal\n");
            } else {
              printf("    Port B polarity = inverted\n");
            }
            if (status & 0x1<<5) {
              printf("    Port B  = pull up\n");
            } else {
              printf("    Port B  = pull down\n");
            }
            break;
          case 2:   /* Port C Low */
	    printf("    Port C Low = %#x\n", input);
            if (status & 0x1<<2) {
              printf("    Port C Low polarity = normal\n");
            } else {
              printf("    Port C Low polarity = inverted\n");
            }
            if (status & 0x1<<6) {
              printf("    Port C Low  = pull up\n");
            } else {
              printf("    Port C Low  = pull down\n");
            }
            break;
          case 3:   /* Port C High */
	    printf("    Port C High = %#x\n", input);
            if (status & 0x1<<3) {
              printf("    Port C High polarity = normal\n");
            } else {
              printf("    Port C High polarity = inverted\n");
            }
            if (status & 0x1<<7) {
              printf("    Port C High  = pull up\n");
            } else {
              printf("    Port C High  = pull down\n");
            }
            break;
        }
      } while (toContinue());
      break;
    case 'g':
      strncpy(serial, PMD_GetSerialNumber(hid), 9);
      printf("Serial Number = %s\n", serial);
      break;
    case 't':
      printf("\nTesting Digital Bit I/O....\n");
      do {
	if (device == USBERB24_PID) {
	  printf("Enter a port number [0-3]: ");
	  scanf("%hhd", &port);
	  if (port > 3) break;
	} else {
	  printf("Enter a port number [2-3]: ");  // only CL and CH on ERB08
	  scanf("%hhd", &port);
	  printf("port = %d\n", port);
	  if (port != 2 &&  port != 3) continue;
	}
        printf("Select the Pin in port  %d  [0-7] :", port);
        scanf("%hhd", &pin);
	printf("Enter a bit value for output (0 | 1) : ");
	scanf("%hhd", &bit_value);
	usbDBitOut_USBERB(hid, port, pin, bit_value);
        status = usbGetStatus_USBERB(hid);
	input = usbDBitIn_USBERB(hid, port, pin);
	printf("    Port %d  Pin %d = %#x\n", port, pin, input);
        switch (port) {
          case 0:   /* Port A */
            if (status & 0x1<<0) {
              printf("    Port A polarity = normal\n");
            } else {
              printf("    Port A polarity = inverted\n");
            }
            if (status & 0x1<<4) {
              printf("    Port A  = pull up\n");
            } else {
              printf("    Port A  = pull down\n");
            }
            break;
          case 1:   /* Port B */
            if (status & 0x1<<1) {
              printf("    Port B polarity = normal\n");
            } else {
              printf("    Port B polarity = inverted\n");
            }
            if (status & 0x1<<1) {
              printf("    Port B  = pull up\n");
            } else {
              printf("    Port B  = pull down\n");
            }
            break;
          case 2:   /* Port C Low */
            if (status & 0x1<<2) {
              printf("    Port C Low polarity = normal\n");
            } else {
              printf("    Port C Low polarity = inverted\n");
            }
            if (status & 0x1<<6) {
              printf("    Port C Low  = pull up\n");
            } else {
              printf("    Port C Low  = pull down\n");
            }
            break;
          case 3:   /* Port C High */
            if (status & 0x1<<3) {
              printf("    Port C High polarity = normal\n");
            } else {
              printf("    Port C High polarity = inverted\n");
            }
            if (status & 0x1<<7) {
              printf("    Port C High  = pull up\n");
            } else {
              printf("    Port C High  = pull down\n");
            }
            break;
        }
      } while (toContinue());
      break;
    case 's':
      status = usbGetStatus_USBERB(hid);      
      printf("Status = %#x\n", status);
      if (device == USBERB24_PID) {
	if (status & 0x1<<1) {
	  printf("    Port A polarity = normal\n");
	} else {
	  printf("    Port A polarity = inverted\n");
	}
	if (status & 0x1<<4) {
	  printf("    Port A  = pull up\n");
	} else {
	  printf("    Port A  = pull down\n");
	}
	/* Port B */
	if (status & 0x1<<2) {
	  printf("    Port B polarity = normal\n");
	} else {
	  printf("    Port B polarity = inverted\n");
	}
	if (status & 0x1<<4) {
	  printf("    Port B  = pull up\n");
	} else {
	  printf("    Port B  = pull down\n");
	}
      }
      /* Port C Low */
      if (status & 0x1<<3) {
	printf("    Port C Low polarity = normal\n");
      } else {
	printf("    Port C Low polarity = inverted\n");
      }
      if (status & 0x1<<6) {
	printf("    Port C Low  = pull up\n");
      } else {
	printf("    Port C Low  = pull down\n");
      }
      /* Port C High */
      if (status & 0x1<<4) {
	printf("    Port C High polarity = normal\n");
      } else {
	printf("    Port C High polarity = inverted\n");
      }
      if (status & 0x1<<7) {
	printf("    Port C High  = pull up\n");
      } else {
	printf("    Port C High  = pull down\n");
      }
      break;
    case 'l':
      if (device == USBERB24_PID) {
	printf("Temperature = %f C\n", usbGetTemp_USBERB(hid));
      } else {
        printf("N/A on ERB08\n");
      }
      break;
    case 'r':
      usbReset_USBERB(hid);
      return 0;
      break;
    case 'e':
      ret = hid_close(hid);
      if (ret != HID_RET_SUCCESS) {
	fprintf(stderr, "hid_close failed with return code %d\n", ret);
	return 1;
      }
      hid_delete_HIDInterface(&hid);
      ret = hid_cleanup();
      if (ret != HID_RET_SUCCESS) {
	fprintf(stderr, "hid_cleanup failed with return code %d\n", ret);
	return 1;
      }
      return 0;
    default:
      break;
    }
  }
}
