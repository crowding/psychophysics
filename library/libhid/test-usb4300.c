/*
 *
 *  Copyright (c) 2007  Warren Jasper <wjasper@tx.ncsu.edu>
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
#include "usb-4303.h"

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
  int i;
  int ch;
  int device = 0;  // either USB-4301 or USB-4303
  char serial[9];
  __u8 pin = 0;
  __u8 bit_value = 0x0;
  __u8 tmp;

  HIDInterface*  hid[2] = {0x0, 0x0};
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
  for (i = 0; i < 2; i++ ) {
    if ((interface = PMD_Find_Interface(&hid[i], i, USB4301_PID)) >= 0) {
      printf("USB 4301 Device is found! Interface = %d\n", interface);
      device = USB4301_PID;
    } else if ((interface = PMD_Find_Interface(&hid[i], i, USB4303_PID)) >= 0) {
      printf("USB 4303 Device is found! Interface = %d\n", interface);
      device = USB4303_PID;
      printf("device = %d\n", device);
    } else {
      fprintf(stderr, "USB 4301 or 4303 not found.\n");
      exit(-1);
    }
  }

  while(1) {
    printf("\nUSB 430X Testing\n");
    printf("----------------\n");
    printf("Hit 'b' to blink LED\n");
    printf("Hit 'c' for event counter.\n");
    printf("Hit 'd' to test digital I/O \n");
    printf("Hit 'e' to exit\n");
    printf("Hit 'g' to get serial number\n");
    printf("Hit 'r' to reset\n");
    printf("Hit 's' to get status\n");
    printf("Hit 't' to test digital bit I/O\n");

    
    while((ch = getchar()) == '\0' || ch == '\n');

    switch(ch) {
    case 'b': /* test to see if led blinks 5 times*/
      usbBlink_USB4303(hid[0], 5);
      break;
    case 'c':
      printf("Configures Chip 1 Counter 1 as a simple event counter.\n");
      printf("Uses 1INP1 as the source input.  Connect DO0 to 1INP1\n");
      usbSetRegister_USB4303(hid[0], 1, CNT_1_MODE_REG,
			     (NEGATIVEEDGE|COUNTUP|ONETIME|BINARY|LOADREG|SRC1|SPECIALGATEOFF|NOGATE));
      usbSetRegister_USB4303(hid[0], 1, CNT_1_LOAD_REG, 0);
      usbLoad_USB4303(hid[0], 1, COUNTER_1);
      usbArm_USB4303(hid[0], 1, COUNTER_1);
      for ( i = 0; i < 13; i++ ) {
	usleep(10000);
	usbDOut_USB4303(hid[0], 0);
	usleep(10000);
	usbDOut_USB4303(hid[0], 1);
      }
      printf("Value should be 13.  Read value = %d\n", usbRead_USB4303(hid[0], 1, COUNTER_1));
      break;
    case 'd':
      printf("\nTesting Digital I/O Write \n");
      printf("Enter a byte number [0-0xff] : " );
      scanf("%hhx", &tmp);
      usbDOut_USB4303(hid[0], (__u8)tmp);
      printf("\nTesting Digital I/O Read \n");
      printf("%#hhx\n", usbDIn_USB4303(hid[0]));
      break;
    case 't':
      printf("\nTesting Digital Bit I/O Write \n");
      printf("Select the bit [0-7] : ");
      scanf("%hhd", &pin);
      printf("Enter a bit value for output (0 | 1) : ");
      scanf("%hhd", &bit_value);
      usbDBitOut_USB4303(hid[0], pin, bit_value);
      printf("\nTesting Digital Bit I/O Read \n");
      printf("Bit No: %d   Value = %hhx\n", pin, usbDBitIn_USB4303(hid[0], pin));
      break;
    case 'g':
      strncpy(serial, PMD_GetSerialNumber(hid[0]), 9);
      printf("Serial Number = %s\n", serial);
      break;
    case 'r':
      usbReset_USB4303(hid[0]);
      return 0;
      break;
    case 'e':
      for ( i = 0; i < 2; i++ ) {
        ret = hid_close(hid[i]);
        if (ret != HID_RET_SUCCESS) {
	  fprintf(stderr, "hid_close failed with return code %d\n", ret);
	  return 1;
        }
	hid_delete_HIDInterface(&hid[i]);
      }
      ret = hid_cleanup();
      if (ret != HID_RET_SUCCESS) {
	fprintf(stderr, "hid_cleanup failed with return code %d\n", ret);
	return 1;
      }
      return 0;
      break;
    case 's':
      printf("Status = %#x\n", usbGetStatus_USB4303(hid[0]));
      break;
    default:
      break;
    }
  }
}
