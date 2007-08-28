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

/*
 * your kernel needs to be configured with /dev/usb/hiddev support
 * I think most distros are already
 *
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
#include "usb-3100.h"

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

int main(int argc, char **argv) {

  int flag;
  __u8 channel;
  int temp, i;
  int ch;
  unsigned int value;
  char serial[9];

  HIDInterface*  hid = 0x0;
  hid_return ret;
  int nInterfaces = 0;
  
  // Debug information.  Delete when not needed    
  // hid_set_debug(HID_DEBUG_ALL);
  // hid_set_debug_stream(stderr);
  // hid_set_usb_debug(2);

  ret = hid_init();
  if (ret != HID_RET_SUCCESS) {
    fprintf(stderr, "hid_init failed with return code %d\n", ret);
    return -1;
  }

  if ((nInterfaces = PMD_Find_Interface(&hid, 0, USB3105_PID)) >= 0) {
    printf("USB 3105 Device is found! Number of Interfaces = %d\n", nInterfaces);
  } else if ((nInterfaces = PMD_Find_Interface(&hid, 0, USB3106_PID)) >= 0) {
    printf("USB 3106 Device is found! Number of Interfaces = %d\n", nInterfaces);
  } else if ((nInterfaces = PMD_Find_Interface(&hid, 0, USB3114_PID)) >= 0) {
    printf("USB 3114 Device is found! Number of Interfaces = %d\n", nInterfaces);
  } else {
    fprintf(stderr, "USB 31XX  not found.\n");
    exit(1);	
  }

  /* config mask 0x01 means all inputs */
  usbDConfigPort_USB31XX(hid, DIO_DIR_OUT);
  usbDOut_USB31XX(hid, 0);

  while(1) {
    printf("\nUSB 31XX Testing\n");
    printf("----------------\n");
    printf("Hit 'a' for analog out\n");
    printf("Hit 'b' to blink \n");
    printf("Hit 'c' to test counter\n");
    printf("Hit 'd' to test digital output\n");
    printf("Hit 'e' to exit\n");
    printf("Hit 'g' to get serial number\n");
    printf("Hit 'r' to reset\n");
    printf("Hit 's' to get status\n");

    while((ch = getchar()) == '\0' ||
      ch == '\n');

    switch(ch) {
      case 'a':
	printf("Testing the analog output...\n");
        printf("Enter channel [0-15]:");
        scanf("%d", &temp);
        channel = (__u8) temp;
        for ( i = 0; i < 2; i++ ) {
          for ( value = 0; value < 0xffff; value += 16 ) {
	    usbAOut_USB31XX(hid, channel, (__u16) value, 0);
	  }
        }
        break;
      case 'b': /* test to see if led blinks  4 times*/
        usbBlink_USB31XX(hid, 4);
        break;
      case 'c':
        printf("connect CTR and DIO0\n");
        usbInitCounter_USB31XX(hid);
        sleep(1);
        flag = fcntl(fileno(stdin), F_GETFL);
        fcntl(0, F_SETFL, flag | O_NONBLOCK);
        do {
          usbDOut_USB31XX(hid, 1);
	  usleep(200000);
          usbDOut_USB31XX(hid, 0);
	  printf("Counter = %d\n",usbReadCounter_USB31XX(hid));
        } while (!isalpha(getchar()));
        fcntl(fileno(stdin), F_SETFL, flag);
        break;
      case 'd':
	printf("\nTesting Digital I/O....\n");
        printf("Enter a byte number [0-0xff]: " );
        scanf("%x", &temp);
        usbDConfigPort_USB31XX(hid, DIO_DIR_OUT);
        usbDOut_USB31XX(hid, (__u8)temp);
        break;
      case 's':
        printf("Status = %#x\n", usbGetStatus_USB31XX(hid));
	break;
      case 'r':
        usbReset_USB31XX(hid);
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
	break;
      case 'g':
        strncpy(serial, PMD_GetSerialNumber(hid), 9);
        printf("Serial Number = %s\n", serial);
        break;
      default:
        break;
    }
  }
}
