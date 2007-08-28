/*
 *
 *  Copyright (c) 2004-2005 Warren Jasper <wjasper@tx.ncsu.edu>
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
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
//#include <asm/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#include "pmd.h"

#define  PATHLEN 2

// Driver Functions

int PMD_Find_Interface(HIDInterface** hid, int interface, int product_id)
{
  hid_return ret;

  HIDInterfaceMatcher matcher = { MCC_VID, 0x0, NULL, NULL, 0 };

  matcher.product_id = product_id;

  *hid = hid_new_HIDInterface();
  if (*hid == 0) {
    fprintf(stderr, "hid_new_HIDInterface() failed, out of memory?\n");
    return -1;
  }
  ret = hid_force_open(*hid, interface, &matcher, 3);
  if (ret != HID_RET_SUCCESS) {
    fprintf(stderr, "hid_force_open failed with return code %d\n", ret);
    return -1;
  } else {
    return interface;
  }
}

char * PMD_GetSerialNumber(HIDInterface* hid)
{
  struct usb_dev_handle* udev = hid->dev_handle;
  static char serial[80];
  int ret;

  if (usb_device(udev)->descriptor.iSerialNumber) {
    ret = usb_get_string_simple(udev, usb_device(udev)->descriptor.iSerialNumber, serial, sizeof(serial));
    if (ret > 0) {
      serial[8] = '\0';
      return serial;
    } else {
      printf("Unable to fetch serial number string.\n");
      return 0;
    }
  }
  return 0;
}

int PMD_SendOutputReport(HIDInterface* hid, __u8 reportID, __u8* vals, int num_vals, int delay)
{
  int ret;

  if (reportID == 0) { // use interrupt endpoint 1 
    ret = usb_interrupt_write(hid->dev_handle, USB_ENDPOINT_OUT | 1, (char *) vals, num_vals, delay);
    if (ret != num_vals) { // try one more time:
      ret = usb_interrupt_write(hid->dev_handle, USB_ENDPOINT_OUT | 1, (char *) vals, num_vals, delay);
    }
  } else { // use the control endpoint (Some FS devices use this)
    ret = usb_control_msg(hid->dev_handle,
			  (USB_TYPE_CLASS| USB_RECIP_INTERFACE),
			  SET_REPORT,
			  (OUTPUT_REPORT | reportID),
			  0,
			  (char *) vals,
			  num_vals,
			  delay);
  }
  return ret;    
}


int PMD_GetInputReport(HIDInterface* hid, __u8 reportID, __u8 *vals, int nbytes, int delay)
{
  char data[33];
  int ret;

  if ( reportID == 0 ) { // it's an LS device, use endpoint 1 
    ret = usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1, data, nbytes, delay);
    if ( ret < 0 ) {
      perror("PMD_GetInputReport");
    }
    memcpy(vals, data, nbytes);
    return ret;
  }
  return -1;
}

int PMD_GetFeatureReport(HIDInterface* hid, __u8 reportID, __u8 *vals, int num_vals, int delay)
{
  int ret = 0;

  ret = usb_control_msg(hid->dev_handle,
			0xa1,
			GET_REPORT,
			FEATURE_REPORT,
			0,
			(char *) vals,
			num_vals,
			delay);

    return ret;
}
