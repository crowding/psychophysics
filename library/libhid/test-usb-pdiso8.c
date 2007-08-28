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
#include "usb-pdiso8.h"

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

int main (int argc, char **argv)
{
  int temp;
  int ch;
  char serial[9];
  
  HIDInterface*  hid = 0x0;
  hid_return ret;
  int interface;
  __u8 port;
  __u8 pin = 0;
  __u8 bit_value;
  
  // Debug information.  Delete when not needed    
  //  hid_set_debug(HID_DEBUG_ALL);
  //  hid_set_debug_stream(stderr);
  //  hid_set_usb_debug(2);

  ret = hid_init();
  if (ret != HID_RET_SUCCESS) {
    fprintf(stderr, "hid_init failed with return code %d\n", ret);
    return -1;
  }

  if ((interface = PMD_Find_Interface(&hid, 0, USBPDISO8_PID)) >= 0) {
    printf("USB PDISO8 Device is found! Interface = %d\n", interface);
  } else if ((interface = PMD_Find_Interface(&hid, 0, USBSWITCH_AND_SENSE_PID)) >= 0) {
    printf("USB Switch & Sense 8/8  Device is found! Interface = %d\n", interface);
  } else {
    fprintf(stderr, "USB PDISO8 and Switch & Sense 8/8 not found.\n");
    exit(-1);
  }

  while(1) {
    printf("\nUSB PDISO8 or Switch & Sense Testing\n");
    printf("----------------\n");
    printf("Hit 'b' to blink LED\n");
    printf("Hit 'd' to test digital I/O \n");
    printf("Hit 'e' to exit\n");
    printf("Hit 'g' to get serial number\n");
    printf("Hit 't' to test digital bit I/O\n");
    
    while((ch = getchar()) == '\0' || ch == '\n');
    
    switch(ch) {
    case 'b': /* test to see if led blinks */
      usbBlink_USBPDISO8(hid);
      break;
    case 'd':
      printf("\nTesting Digital I/O....\n");
      do {
	printf("Enter a port number: 0 - Relay Port, 1 - ISO Port: ");
	scanf("%hhd", &port);
	switch (port) {
        case 0:  // Relay Port output only
          printf("Enter a byte number [0-0xff] : " );
          scanf("%x", &temp);
          usbDOut_USBPDISO8(hid, port, (__u8)temp);
          break;
        case 1:  // ISO Port input only
	  printf("ISO Port = %#x\n", usbDIn_USBPDISO8(hid, port));
	  break;
      default:
	printf("Invalid port number.\n");
        break;
	}
      } while (toContinue());
      break;
    case 't':
      do {
	printf("\nTesting Digital Bit I/O....\n");
	printf("Enter a port number: 0 - Relay Port, 1 - ISO Port: ");
	scanf("%hhd", &port);
	printf("Select the Pin in port  %d  [0-7] :", port);
	scanf("%hhd", &pin);
	if (pin > 7) break;
	switch (port) {
        case 0:  // Relay Port output only
	  printf("Enter a bit value for output (0 | 1) : ");
	  scanf("%hhd", &bit_value);
	  usbDBitOut_USBPDISO8(hid, port, pin, bit_value);
          break;
	case 1:
	  printf("ISO Port = %d  Pin = %d, Value = %d\n", port, pin, usbDBitIn_USBPDISO8(hid, port, pin));
          break;
	default:
	  printf("Invalid port number.\n");
	  break;
	}
      } while (toContinue());
      break;    
    case 'g':
        strncpy(serial, PMD_GetSerialNumber(hid), 9);
        printf("Serial Number = %s\n", serial);
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
  



