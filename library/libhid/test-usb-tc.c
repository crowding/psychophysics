/*
 *
 *  Copyright (c) 2004-2005  Warren Jasper <wjasper@tx.ncsu.edu>
 *                           Measurement Computing
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
#include "usb-tc.h"

float volts_FS(const int gain, const signed short num);


/* Test Program */
float celsius2fahr( float celsius)
{
  return (celsius*9.0/5.0 + 32.);
}

float fahr2celsius( float fahr)
{
  return (fahr - 32.)*5.0/9.0;
}


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

  int ch;
  __u8 bIReg, bOReg;
  float temperature;
  int flag;
  char type;

  HIDInterface*  hid = 0x0;  // Composite device with 1 interface.
  hid_return ret;
  int interface;
  char serial[9];
  
  // Debug information.  Delete when not needed    
  //  hid_set_debug(HID_DEBUG_ALL);
  //  hid_set_debug_stream(stderr);
  //  hid_set_usb_debug(2);

  ret = hid_init();
  if (ret != HID_RET_SUCCESS) {
    fprintf(stderr, "hid_init failed with return code %d\n", ret);
    return -1;
  }

  if ((interface = PMD_Find_Interface(&hid, 0, USBTC_PID)) < 0) {
      fprintf(stderr, "USB TC not found.\n");
      exit(1);
  } else {
      printf("USB TC Device is found! Interface = %d\n", interface);
  }

  /* config mask 0x01 means all inputs */
  usbDConfigPort_USBTC(hid, DIO_DIR_OUT);
  usbDOut_USBTC(hid, 0x0);

  while(1) {
    printf("\nUSB TC Testing\n");
    printf("----------------\n");
    printf("Hit 'b' to blink LED\n");
    printf("Hit 'c' to calibrate\n");
    printf("Hit 'd' to test DIO\n");
    printf("Hit 'e' to exit\n");
    printf("Hit 'f' for burnout status\n");
    printf("Hit 'g' to get serial number\n");    
    printf("Hit 'r' to reset\n");
    printf("Hit 'p' read the CJC\n");
    printf("Hit 's' to get status\n");
    printf("Hit 't' to measure temperature\n");

    while((ch = getchar()) == '\0' ||
      ch == '\n');

    switch(tolower(ch)) {
      case 'b': /* test to see if led blinks */
        usbBlink_USBTC(hid);
        break;
      case 'c': /* calibration */
        usbCalibrate_USBTC(hid);
        break;
      case 'f':  /* Get status of thermocouple burnout detection */
	 printf("Burnout status = %#x\n", usbGetBurnoutStatus_USBTC(hid, 0xf));
	 break;
      case 'g':
        strncpy(serial, PMD_GetSerialNumber(hid), 9);
        printf("Serial Number = %s\n", serial);
        break;
      case 'p':  /* read the CJC */
        usbTin_USBTC(hid, CJC0, 0, &temperature);
	printf("CJC 0 = %.2f degress Celsius or %.2f degrees Fahrenheit.\n", temperature,
	        celsius2fahr(temperature));
        usbTin_USBTC(hid, CJC1, 0, &temperature);
	printf("CJC 1 = %.2f degress Celsius or %.2f degrees Fahrenheit.\n", temperature,
	        celsius2fahr(temperature));
        break;
      case 'd': /* test to see if led blinks */
        printf("conect DIO0 - DIO4\n");
	printf("conect DIO1 - DIO5\n");
	printf("conect DIO2 - DIO6\n");
	printf("conect DIO3 - DIO7\n");
	usbDConfigBit_USBTC(hid, 0,  DIO_DIR_OUT);
	usbDConfigBit_USBTC(hid, 1,  DIO_DIR_OUT);
	usbDConfigBit_USBTC(hid, 2,  DIO_DIR_OUT);
	usbDConfigBit_USBTC(hid, 3,  DIO_DIR_OUT);
	usbDConfigBit_USBTC(hid, 4,  DIO_DIR_IN);
	usbDConfigBit_USBTC(hid, 5,  DIO_DIR_IN);
	usbDConfigBit_USBTC(hid, 6,  DIO_DIR_IN);
	usbDConfigBit_USBTC(hid, 7,  DIO_DIR_IN);
	do {
  	  printf("Enter value [0-f]: ");
	  scanf("%hhx", &bIReg);
	  bIReg &= 0xf;
  	  usbDOut_USBTC(hid, bIReg);
	  usbDIn_USBTC(hid, &bOReg);
	  printf("value = %#hhx\n", bOReg);
	} while (toContinue());
	break;
      case 's':
        printf("Status = %#x\n", usbGetStatus_USBTC(hid));
	break;
      case 'r':
        usbReset_USBTC(hid);
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
      case 't':
        printf("Connect thermocouple to channel 0\n");
	printf(" Select Thermocouple Type [JKSRBETN]: ");
	scanf("%s", &type);
	switch(type) {
	case 'J':
	  bIReg = TYPE_J;
	  printf("Type J Thermocouple Selected: \n");
	  break;
	case 'K':
	  bIReg = TYPE_K;
  	  printf("Type K Thermocouple Selected: \n");
	  break;
	case 'T':
	  bIReg = TYPE_T;
    	  printf("Type T Thermocouple Selected: \n");
	  break;
	case 'E':
	  bIReg = TYPE_E;
    	  printf("Type E Thermocouple Selected: \n");
	  break;
	case 'R':
	  bIReg = TYPE_R;
      	  printf("Type R Thermocouple Selected: \n");
	  break;
	case 'S':
	  bIReg = TYPE_S;
       	  printf("Type S Thermocouple Selected: \n");
	  break;
	case 'B':
	  bIReg = TYPE_B;
       	  printf("Type B Thermocouple Selected: \n");
	  break;
	case 'N':
	  bIReg = TYPE_N;
       	  printf("Type N Thermocouple Selected: \n");
	  break;
        default:
	  printf("Unknown or unsupported thermocopule type.\n");
	  break;
	}
        usbSetItem_USBTC(hid, ADC_0, CH_0_TC, bIReg);
        flag = fcntl(fileno(stdin), F_GETFL);
        fcntl(0, F_SETFL, flag | O_NONBLOCK);
	do {
          usbTin_USBTC(hid, CH0, 0, &temperature);
  	  printf("%.2f degress Celsius or %.2f degrees Fahrenheit.\n", temperature,
		 celsius2fahr(temperature));
  	  sleep(1);
	} while (!isalpha(getchar()));
	fcntl(fileno(stdin), F_SETFL, flag);
	break;
      default:
        break;
    }
  }
}
