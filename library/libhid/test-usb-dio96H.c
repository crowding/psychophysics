/*
 *
 *  Copyright (c) 2004-2007     Warren Jasper <wjasper@tx.ncsu.edu>
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
#include "usb-dio96H.h"

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
  
  int flag;
  __u8 input, pin = 0; 
  int temp;
  int ch;
  char serial[9];

  HIDInterface*  hid = 0x0;
  hid_return ret;
  int interface;
  int device = 0;  // either USB-1096HFS, USB-DIO96H or USB-DIO96H/50
  
  // Debug information.  Delete when not needed    
  //  hid_set_debug(HID_DEBUG_ALL);
  //  hid_set_debug_stream(stderr);
  //  hid_set_usb_debug(2);

  ret = hid_init();
  if (ret != HID_RET_SUCCESS) {
    fprintf(stderr, "hid_init failed with return code %d\n", ret);
    return -1;
  }

  if ((interface = PMD_Find_Interface(&hid, 0, USB1096HFS_PID)) >= 0) {
    printf("USB 1096HFS Device is found! Interface = %d\n", interface);
    device = USB1096HFS_PID;
  } else if ((interface = PMD_Find_Interface(&hid, 0, USBDIO96H_PID)) >= 0) {
    printf("USB DIO96H Device is found! Interface = %d\n", interface);
    device = USBDIO96H_PID;	     
  } else if ((interface = PMD_Find_Interface(&hid, 0, USBDIO96H_50_PID)) >= 0) {
    printf("USB DIO96H/50 Device is found! Interface = %d\n", interface);
    device = USBDIO96H_50_PID;	     
  } else {
    fprintf(stderr, "USB 1096HFS, DIO96H or DIO96H/50  not found.\n");
  }

  usbDConfigPort_USBDIO96H(hid, DIO_PORT0A, DIO_DIR_OUT);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT0B, DIO_DIR_IN);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT0C_LOW, DIO_DIR_OUT);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT0C_HI, DIO_DIR_IN);

  usbDConfigPort_USBDIO96H(hid, DIO_PORT1A, DIO_DIR_OUT);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT1B, DIO_DIR_IN);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT1C_LOW, DIO_DIR_OUT);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT1C_HI, DIO_DIR_IN);

  usbDConfigPort_USBDIO96H(hid, DIO_PORT2A, DIO_DIR_OUT);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT2B, DIO_DIR_IN);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT2C_LOW, DIO_DIR_OUT);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT2C_HI, DIO_DIR_IN);

  usbDConfigPort_USBDIO96H(hid, DIO_PORT3A, DIO_DIR_OUT);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT3B, DIO_DIR_IN);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT3C_LOW, DIO_DIR_OUT);
  usbDConfigPort_USBDIO96H(hid, DIO_PORT3C_HI, DIO_DIR_IN);

  while(1) {
    printf("\nUSB DIO96H Testing\n");
    printf("----------------\n");
    printf("Hit 'b' to blink LED\n");
    printf("Hit 'c' to test counter \n");
    printf("Hit 'd' to test digital I/O \n");
    printf("Hit 'e' to exit\n");
    printf("Hit 'g' to get serial number\n");
    printf("Hit 's' to get status\n");
    printf("Hit 'r' to reset\n");
    printf("Hit 't' to test digital bit I/O\n");
    

    while((ch = getchar()) == '\0' || ch == '\n');
    
    switch(ch) {
    case 'b': /* test to see if led blinks */
      usbBlink_USBDIO96H(hid);
      break;
    case 'c':
      printf("connect pin P1A0 and CTR\n");
      usbInitCounter_USBDIO96H(hid);
      sleep(1);
      usbDOut_USBDIO96H(hid, DIO_PORT0A, 0x0);
      flag = fcntl(fileno(stdin), F_GETFL);
      fcntl(0, F_SETFL, flag | O_NONBLOCK);
      do {
        usbDOut_USBDIO96H(hid, DIO_PORT0A, 0x1);
        usbDOut_USBDIO96H(hid, DIO_PORT0A, 0x0);
	printf("Counter = %d\n",usbReadCounter_USBDIO96H(hid));
      } while (!isalpha(getchar()));
      fcntl(fileno(stdin), F_SETFL, flag);
      break;
    case 'd':
      printf("\nTesting Digital I/O....\n");
      printf("connect pins 21 through 28 <=> 32 through 39 and pins 1-4 <==> 5-8\n");
      do {
        printf("Enter a byte number [0-0xff] : " );
        scanf("%x", &temp);
        usbDOut_USBDIO96H(hid, DIO_PORT0A, (__u8)temp);
        input = usbDIn_USBDIO96H(hid, DIO_PORT0B);
        printf("The number you entered = %#x\n\n",input);
        printf("Enter a nibble [0-0xf] : " );
        scanf("%x", &temp);
        usbDOut_USBDIO96H(hid, DIO_PORT0C_LOW, (__u8)temp);
	input = usbDIn_USBDIO96H(hid, DIO_PORT0C_HI);
        printf("The number you entered = %#x\n",input);
      } while (toContinue());
      break;
    case 'g':
      usbReadCode_USBDIO96H(hid, 0x200000, 8, (__u8 *) serial);
      serial[8] = '\0';
      printf("Serial Number = %s\n", serial);
      break;
    case 't':
      //reset the pin values
      usbDOut_USBDIO96H(hid,DIO_PORT0A,0x0);
      printf("\nTesting Bit  I/O....\n");
      printf("Enter a bit value for output (0 | 1) : ");
      scanf("%d", &temp);
      input = (__u8) temp;
      printf("Select the Pin in port A [0-7] :");
      scanf("%d", &temp);
      pin = (__u8) temp;
      usbDBitOut_USBDIO96H(hid, DIO_PORT0A, pin, input);
      printf("The number you entered 2^%d = %d \n",
	     temp,usbDIn_USBDIO96H(hid, DIO_PORT0B));
      break;
    case 's':
      printf("Status = %#x\n", usbGetStatus_USBDIO96H(hid));
      break;
    case 'r':
      usbReset_USBDIO96H(hid);
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
    default:
      break;
    }
  }
}
  



