/*
 *
 *  Copyright (c) 2004-2005  Warren Jasper <wjasper@tx.ncsu.edu>
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
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <asm/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <linux/hiddev.h>

#include "pmd.h"
#include "usb-dio24.h"

static __u8 PortC = 0;

/* configures digital port */
void usbDConfigPort_USBDIO24(HIDInterface* hid, __u8 port, __u8 direction)
{
  struct {
    __u8 cmd;
    __u8 port;
    __u8 direction;
    __u8 pad[5];
  } report;

  report.cmd = DCONFIG;
  report.port = port;
  report.direction = direction;

  PMD_SendOutputReport(hid, 0, (__u8*) &report, sizeof(report), LS_DELAY);
}

/* reads digital port  */
void usbDIn_USBDIO24(HIDInterface* hid, __u8 port, __u8* din_value)
{
  __u8 cmd[8];
  
  cmd[0] = DIN;
  cmd[1] = port;
  
  PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
  PMD_GetInputReport(hid, 0, din_value, 1, LS_DELAY);
  
  if (port == DIO_PORTC_HI)  *din_value >>= 4;
  if (port == DIO_PORTC_LOW) *din_value &= 0xf;
}

/* writes digital port */
void usbDOut_USBDIO24(HIDInterface* hid, __u8 port, __u8 value) 
{
  __u8 cmd[8];
  
  cmd[0] = DOUT;
  cmd[1] = port;
  cmd[2] = value;

  if (port == DIO_PORTC_LOW) {
    PortC &= (0xf0);
    PortC |= (value & 0xf);
    cmd[2] = PortC;
  }

  if (port == DIO_PORTC_HI) {
    PortC &= (0x0f);
    PortC |= (value << 0x4);
    cmd[2] = PortC;
  }

  PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
}

/* reads digital port bit */
__u8 usbDBitIn_USBDIO24(HIDInterface* hid, __u8 port, __u8 bit) 
{
  __u8 cmd[8];
  __u8 value;

  cmd[0] = DBIT_IN;
  cmd[1] = port;
  cmd[2] = bit;

  PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
  PMD_GetInputReport(hid, 0, &value, sizeof(value), LS_DELAY);

  return value;
}

/* writes digital port bit */
void usbDBitOut_USBDIO24(HIDInterface* hid, __u8 port, __u8 bit, __u8 value)
{
  __u8 cmd[8];
  
  cmd[0] = DBIT_OUT;
  cmd[1] = port;
  cmd[2] = bit;
  cmd[3] = value;

  PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
}

/* Initialize the counter */
void usbInitCounter_USBDIO24(HIDInterface* hid)
{
  __u8 cmd[8];
  
  cmd[0] = CINIT;

  PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
}

__u32 usbReadCounter_USBDIO24(HIDInterface* hid)
{
  __u8 cmd[8];
  __u32 value;

  cmd[0] = CIN;

  PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
  PMD_GetInputReport(hid, 0, (__u8  *) &value, sizeof(value), LS_DELAY);

  return value;
}

void usbReadMemory_USBDIO24(HIDInterface* hid, __u16 address, __u8 *data, __u8 count)
{
  __u8 cmd[8];
 
  cmd[0] = MEM_READ;
  cmd[1] = (__u8) (address & 0xff);  // low byte
  cmd[2] = (__u8) (address >> 0x8);  // high byte
  cmd[3] = count;

  PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
  PMD_GetInputReport(hid, 0, data, count, LS_DELAY);
}

/* blinks the LED of USB device */
void usbBlink_USBDIO24(HIDInterface* hid)
{
  struct {
    __u8 cmd;
    __u8 pad[7];
  } report;

  report.cmd = BLINK_LED;
  PMD_SendOutputReport(hid, 0, (__u8*) &report, sizeof(report), LS_DELAY);
}

/* resets the USB device */
int usbReset_USBDIO24(HIDInterface* hid)
{
  __u8 cmd[8];

  cmd[0] = RESET;

  return PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
}

__u8 usbGetID_USBDIO24(HIDInterface* hid)
{
  __u8 cmd[8];
  __u8 data;

  cmd[0] = GET_ID;

  PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
  PMD_GetInputReport(hid, 0, &data, 1, LS_DELAY);

  return data;
}

void usbSetID_USBDIO24(HIDInterface* hid, __u8 id)
{
  __u8 cmd[8];

  cmd[0] = SET_ID;
  cmd[1] = id;

  PMD_SendOutputReport(hid, 0, cmd, sizeof(cmd), LS_DELAY);
}

