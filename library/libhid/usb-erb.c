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
#include "usb-erb.h"

#define FS_DELAY (500)
/* reads digital port  */
__u8 usbDIn_USBERB(HIDInterface* hid, __u8 port)
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
void usbDOut_USBERB(HIDInterface* hid, __u8 port, __u8 value) 
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
__u8 usbDBitIn_USBERB(HIDInterface* hid, __u8 port, __u8 bit) 
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
void usbDBitOut_USBERB(HIDInterface* hid, __u8 port, __u8 bit, __u8 value)
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

void usbReadMemory_USBERB(HIDInterface* hid, __u16 address, __u8 count, __u8* memory)
{
  /*
    The command reads data from the configuration memory (EEPROM).
    All of the memory may be read.  The USB hub chip EEPROM may be
    read, and its address range is 0x0400 - 0x04FF.
  */

    struct t_arg {
    __u8 reportID;
    __u8 address[2];
    __u8 type;
    __u8 count;
  } arg;

  if ( count > 62 ) count = 62;
  arg.reportID = MEM_READ;
  arg.address[0] = address & 0xff;         // low byte
  arg.address[1] = (address >> 8) & 0xff;  // high byte
  arg.count = count;

  PMD_SendOutputReport(hid, MEM_READ, (__u8 *) &arg, sizeof(arg), FS_DELAY);
  usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &memory, count, FS_DELAY);
}
int usbWriteMemory_USBERB(HIDInterface* hid, __u16 address, __u8 count, __u8* data)
{
  /*
    This command writes to non-volatile EEPROM memory on the device.  The non-volatile
    memory is used to store calibration coefficients, system information, and user data.  Locations
    0x000-0x07F are reserved for firmware use and my not be written.  This device has external
    EEPROM for the USB hub chip configuration, and the values for that EEPROM may be written
    through this command.  The address range for the hub EEPROM is 0x0400-0x04FF.
  */
  int i;
  struct t_mem_write_report {
    __u8 reportID;
    __u8 address[2];
    __u8 count;
    __u8 data[count];
  } arg;

  if ( address <= 0x7f ) return -1;
  if ( count > 59 ) count = 59;

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
void usbBlink_USBERB(HIDInterface* hid)
{
    __u8 reportID = BLINK_LED;

    PMD_SendOutputReport(hid, BLINK_LED, &reportID, sizeof(reportID), FS_DELAY);
}

/* resets the USB device */
int usbReset_USBERB(HIDInterface* hid)
{
  __u8 reportID = RESET;

  return PMD_SendOutputReport(hid, RESET, &reportID, sizeof(reportID), FS_DELAY);
}
__u16 usbGetStatus_USBERB(HIDInterface* hid)
{
  /*
    Bit 0: Port A polarity setting       (0 = inverted,  1 = normal)  (N/A on ERB08)
    Bit 1: Port B polarity setting       (0 = inverted,  1 = normal)  (N/A on ERB08)
    Bit 2: Port C Low polarity setting   (0 = inverted,  1 = normal)
    Bit 3: Port C High polarity setting  (0 = inverted,  1 = normal)
    Bit 4: Port A pull-up setting        (0 = pull down, 1 = pull up) (N/A on ERB08)
    Bit 5: Port B pull-up setting        (0 = pull down, 1 = pull up) (N/A on ERB08)
    Bit 6: Port C Low pull-up setting    (0 = pull down, 1 = pull up)
    Bit 7: Port C High pull-up setting   (0 = pull down, 1 = pull up)
  */

  int nread;
  __u16 status;
  int try = 10;
  struct t_statusReport {
    __u8 reportID;
    __u8 status[2];
  } statusReport;

  statusReport.reportID = GET_STATUS;
    
  PMD_SendOutputReport(hid, GET_STATUS, &statusReport.reportID, 1, FS_DELAY);
  do {
    statusReport.reportID = 0x0;
    nread = usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
			       (char *) &statusReport, sizeof(statusReport), FS_DELAY);
    if (try-- == 0) {
      printf("Error is getting status from USB-ERB\n.");
      break;
    }
  } while (statusReport.reportID != GET_STATUS && (nread != sizeof(statusReport)));
  memcpy(&status, statusReport.status, 2);
  return status;
}

float usbGetTemp_USBERB(HIDInterface* hid)
{
  __s16 temp;
  __u8 reportID = GET_TEMP;
  struct t_get_temp { 
    __u8 reportID;
    __u8 temperature[2];
  } get_temp;

  PMD_SendOutputReport(hid, GET_TEMP, &reportID, sizeof(reportID), FS_DELAY);
  usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &get_temp, sizeof(get_temp), FS_DELAY);
  memcpy(&temp, get_temp.temperature, 2);
  return (temp*0.1);
}

void usbPrepareDownload_USBERB(HIDInterface* hid)
{
  /*
    This command puts the device into code update mode.  The unlock code must be correct as a
    further safety device.  Call this once before sending code with usbWriteCode.  If not in
    code update mode, any usbWriteCode will be ignored.  A usbReset command must be issued at
    the end of the code download in order to return the device to operation with the new code.
  */

  struct t_download {
    __u8 reportID;
    __u8 unlock_code;
  } download;

  download.reportID = PREPARE_DOWNLOAD;
  download.unlock_code = 0xad;
  
  PMD_SendOutputReport(hid, PREPARE_DOWNLOAD,  (__u8 *)  &download, sizeof(download), FS_DELAY);
}

void usbWriteCode_USBERB(HIDInterface* hid, __u32 address, __u8 count, __u8 data[])
{
  /*
    This command writes to the program memory in the device.  This command is not accepted
    unless the device is in update mode.  This command will normally be used when downloading
    a new hex file, so it supports memory ranges that may be found in the hex file.  

    The address ranges are:

    0x000000 - 0x007AFF:  Microcontroller FLASH program memory
    0x200000 - 0x200007:  ID memory (serial number is stored here on main micro)
    0x300000 - 0x30000F:  CONFIG memory (processor configuration data)
    0xF00000 - 0xF03FFF:  EEPROM memory

    FLASH program memory: The device must receive data in 64-byte segments that begin
    on a 64-byte boundary.  The data is sent in messages containing 32 bytes.  count
    must always equal 32.

    Other memory: Any number of bytes up to the maximum (32) may be sent.
    
  */

  struct t_writecode {
    __u8 reportID;
    __u8 address[3];
    __u8 count;
    __u8 data[32];
  } writecode;

  if (count > 32) count = 32;               // 32 byte max 
  writecode.reportID = WRITE_CODE;
  memcpy(writecode.address, &address, 3);   // 24 bit address
  writecode.count = count;                  // the number of byes of data (max 32)
  memcpy(writecode.data, data, count);      // the program data
  PMD_SendOutputReport(hid, WRITE_CODE, (__u8 *) &writecode, count+5, FS_DELAY);
}

int usbReadCode_USBERB(HIDInterface* hid, __u32 address, __u8 count, __u8 data[])
{
  struct t_readCode {
    __u8 reportID;
    __u8 address[3];    // 24 bit start address for the read
    __u8 count;         // the number of bytes to read (62 byte max)
  } readCode;

  struct t_readCodeI {
    __u8 reportID;
    __u8 data[62];
  } readCodeI;

  int bRead;  // bytes read

  if ( count > 62 ) count = 62;  

  readCode.reportID = READ_CODE;
  memcpy(readCode.address, &address, 3);   // 24 bit address
  readCode.count = count;
  PMD_SendOutputReport(hid, READ_CODE, (__u8 *) &readCode, sizeof(readCode), FS_DELAY);
  do {
    readCode.reportID = 0x0;
    bRead = usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
			       (char *) &readCodeI, count+1, FS_DELAY);
  } while (readCodeI.reportID != READ_CODE && (bRead != count+1));
  memcpy(data, readCodeI.data, count);
  return bRead;
}

void usbWriteSerial_USBERB(HIDInterface* hid, __u8 serial[8])
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
