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
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <asm/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <linux/hiddev.h>

#include "pmd.h"
#include "usb-pdiso8.h"

#define FS_DELAY (500)

/* reads digital port  */
__u8 usbDIn_USBPDISO8(HIDInterface* hid, __u8 port)
{
  struct t_read_port {
    __u8 reportID;
    __u8 value;
  } read_port;

  read_port.reportID = DIN;
  read_port.value = port;

  PMD_SendOutputReport(hid, DIN, (__u8*) &read_port, sizeof(read_port), FS_DELAY);
  usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &read_port, sizeof(read_port), FS_DELAY);

  return read_port.value;
}

/* writes digital port */
void usbDOut_USBPDISO8(HIDInterface* hid, __u8 port, __u8 value) 
{
  struct t_write_port {
    __u8 reportID;
    __u8 port;
    __u8 value;
  } write_port;

  write_port.reportID = DOUT;
  write_port.port = port;
  write_port.value = value;

  PMD_SendOutputReport(hid, DOUT, (__u8*) &write_port, sizeof(write_port), FS_DELAY);
}

/* reads digital port bit */
__u8 usbDBitIn_USBPDISO8(HIDInterface* hid, __u8 port, __u8 bit)
{
  struct t_read_bit {
    __u8 reportID;
    __u8 port;
    __u8 value;
  } read_bit;

  read_bit.reportID = DBIT_IN;
  read_bit.port = port;
  read_bit.value = bit;

  PMD_SendOutputReport(hid, DBIT_IN, (__u8*) &read_bit, sizeof(read_bit), FS_DELAY);
  usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &read_bit, sizeof(read_bit), FS_DELAY);
  
  return read_bit.value;
}

/* writes digital port bit */
void usbDBitOut_USBPDISO8(HIDInterface* hid, __u8 port, __u8 bit, __u8 value)
{
  struct t_write_bit {
    __u8 reportID;
    __u8 port;
    __u8 bit_num;
    __u8 value;
  } write_bit;

  write_bit.reportID = DBIT_OUT;
  write_bit.port = port;
  write_bit.bit_num = bit;
  write_bit.value = value;

  PMD_SendOutputReport(hid, DBIT_OUT, (__u8*) &write_bit, sizeof(write_bit), FS_DELAY);
  return;
}

void usbReadMemory_USBPDISO8(HIDInterface* hid, __u16 address, __u8 count, __u8* memory)
{
  /*
    This command reads data from the configuration memory (EEPROM). All
    memory may be read.  Max number of bytes read is 4.
  */

    struct t_arg {
    __u8 reportID;
    __u8 address[2];
    __u8 type;
    __u8 count;
  } arg;

  if ( count > 4 ) count = 4;
  arg.reportID = MEM_READ;
  arg.address[0] = address & 0xff;         // low byte
  arg.address[1] = (address >> 8) & 0xff;  // high byte
  arg.count = count;

  PMD_SendOutputReport(hid, MEM_READ, (__u8 *) &arg, sizeof(arg), FS_DELAY);
  usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &memory, sizeof(memory), FS_DELAY);
}

int usbWriteMemory_USBPDISO8(HIDInterface* hid, __u16 address, __u8 count, __u8* data)
{
  // Locations 0x00-0xF are reserved for firmware and my not be written.
  int i;
  struct t_mem_write_report {
    __u8 reportID;
    __u8 address[2];
    __u8 count;
    __u8 data[count];
  } arg;

  if ( address <= 0xf ) return -1;
  if ( count > 4 ) count = 4;

  arg.reportID = MEM_WRITE;
  arg.address[0] = address & 0xff;         // low byte
  arg.address[1] = (address >> 8) & 0xff;  // high byte

  arg.count = count;
  for ( i = 0; i < count; i++ ) {
    arg.data[i] = data[i];
  }
  PMD_SendOutputReport(hid, MEM_WRITE, (__u8 *) &arg, sizeof(arg), FS_DELAY);
  return 0;
}

/* blinks the LED of USB device */
void usbBlink_USBPDISO8(HIDInterface* hid)
{
    __u8 reportID = BLINK_LED;

    PMD_SendOutputReport(hid, BLINK_LED, &reportID, sizeof(reportID), FS_DELAY);
}

void usbWriteSerial_USBPDISO8(HIDInterface* hid, __u8 serial[8])
{
  // Note: The new serial number will be programmed but not used until hardware reset.
  
  struct t_writeSerialNumber {
    __u8 reportID;
    __u8 serial[8];
  } writeSerialNumber;
  writeSerialNumber.reportID = WRITE_SERIAL;

  memcpy(writeSerialNumber.serial, serial, 8);
  PMD_SendOutputReport(hid, WRITE_SERIAL, (__u8*) &writeSerialNumber, sizeof(writeSerialNumber), FS_DELAY);
}
