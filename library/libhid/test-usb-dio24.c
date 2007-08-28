/*
 *
 *  Copyright (c) 2004-2005  Warren Jasper <wjasper@tx.ncsu.edu>
 *                           Mike Erickson <merickson@nc.rr.com>
 *
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
#include "usb-dio24.h"

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
  int flag;
  __u8 input, pin = 0;
  int temp;
  int ch;
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

  if ((interface = PMD_Find_Interface(&hid, 0, USBDIO24_PID)) >= 0) {
    printf("USB-DIO24 Device is found! interface = %d\n", interface);
  } else if ((interface = PMD_Find_Interface(&hid, 0, USBDIO24H_PID)) >= 0) {
    printf("USB-DIO24H Device is found! interface = %d\n", interface);
  } else {
    fprintf(stderr, "USB-DIO24 and USB-DIO24H not found.\n");
    exit(1);
  }

  usbDConfigPort_USBDIO24(hid, DIO_PORTA, DIO_DIR_OUT);
  usbDConfigPort_USBDIO24(hid, DIO_PORTB, DIO_DIR_IN);
  usbDConfigPort_USBDIO24(hid, DIO_PORTC_LOW, DIO_DIR_OUT);
  usbDConfigPort_USBDIO24(hid, DIO_PORTC_HI, DIO_DIR_IN);
  
  while(1) {
    printf("\nUSB DIO24 Testing\n");
    printf("----------------\n");
    printf("Hit 'b' to blink LED\n");
    printf("Hit 's' to set user id\n");
    printf("Hit 'g' to get user id\n");
    printf("Hit 'n' to get serial number\n");
    printf("Hit 'c' to test counter \n");
    printf("Hit 'd' to test digital I/O \n");
    printf("Hit 't' to test digital bit I/O\n");
    printf("Hit 'e' to exit\n");

    while((ch = getchar()) == '\0' || ch == '\n');
    
    switch(tolower(ch)) {
    case 'b': /* test to see if led blinks */
      usbBlink_USBDIO24(hid);
      break;
    case 's':
      printf("enter a user id :");
      scanf("%d",&temp);
      usbSetID_USBDIO24(hid, temp);
      printf("User ID is set to %d\n", usbGetID_USBDIO24(hid));      
      break;
    case 'g':
      printf("User ID = %d\n", usbGetID_USBDIO24(hid));      
      break;
    case 'c':
      printf("connect pin 21 and 20\n");
      usbInitCounter_USBDIO24(hid);
      flag = fcntl(fileno(stdin), F_GETFL);
      fcntl(0, F_SETFL, flag | O_NONBLOCK);
      do {
        usbDOut_USBDIO24(hid, DIO_PORTA, 1);
        usbDOut_USBDIO24(hid, DIO_PORTA, 0);
	printf("Counter = %d\n",usbReadCounter_USBDIO24(hid));
      } while (!isalpha(getchar()));
      fcntl(fileno(stdin), F_SETFL, flag);
      break;
    case 'd':
      printf("\nTesting Digital I/O....\n");
      printf("connect pins 21 through 28 <=> 32 through 39 and pins 1-4 <==> 5-8\n");
      do {
        printf("Enter a byte number [0-0xff] : " );
        scanf("%x", &temp);
        usbDOut_USBDIO24(hid, DIO_PORTA, (__u8)temp);
        usbDIn_USBDIO24(hid, DIO_PORTB, &input);
        printf("The number you entered = %#x\n\n", input);
	printf("Enter a nibble [0-0xf] : " );
	scanf("%x", &temp);
	usbDOut_USBDIO24(hid, DIO_PORTC_LOW, (__u8)temp);
	usbDIn_USBDIO24(hid, DIO_PORTC_HI, &input);
	printf("The number you entered = %#x\n", input);
      } while (toContinue());
      break;
    case 't':
      //reset the pin values
      usbDOut_USBDIO24(hid, DIO_PORTA,0x0);
      printf("\nTesting Bit  I/O....\n");
      printf("Enter a bit value for output (0 | 1) : ");
      scanf("%d", &temp);
      input = (__u8) temp;
      printf("Select the Pin in port A [0-7] :");
      scanf("%d", &temp);
      pin = (__u8) temp;
      usbDBitOut_USBDIO24(hid, DIO_PORTA, pin, input);
      usbDIn_USBDIO24(hid, DIO_PORTB, &input);
      printf("The number you entered 2^%d = %d \n", temp, input);
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
    case 'n':
      printf("Serial Number = %s\n", PMD_GetSerialNumber(hid));
      break;
    default:
      break;
    }
  }
}
