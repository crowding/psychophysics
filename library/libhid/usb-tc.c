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

#include "pmd.h"
#include "usb-tc.h"

#define FS_DELAY 10000

/* configures digital port */
void usbDConfigPort_USBTC(HIDInterface* hid, __u8 direction)
{
  struct t_config_port {
    __u8 reportID;
    __u8 direction;
  } config_port;

  config_port.reportID = DCONFIG;
  config_port.direction = direction;

  PMD_SendOutputReport(hid, 0, (__u8*) &config_port, sizeof(config_port), FS_DELAY);
}

/* configures digital bit */
void usbDConfigBit_USBTC(HIDInterface* hid, __u8 bit_num, __u8 direction)
{
  struct t_config_bit {
    __u8 reportID;
    __u8 bit_num;      
    __u8 direction;
  } config_bit;

  config_bit.reportID = DCONFIG_BIT;
  config_bit.bit_num = bit_num;
  config_bit.direction = direction;

  PMD_SendOutputReport(hid, 0, (__u8*) &config_bit, sizeof(config_bit), FS_DELAY);
}

/* reads digital port  */
void usbDIn_USBTC(HIDInterface* hid, __u8 *value)
{
  __u8 reportID = DIN;
  struct t_read_port {
    __u8 reportID;
    __u8 value;
  } read_port;

  PMD_SendOutputReport(hid, 0, &reportID, 1, FS_DELAY);
  usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &read_port, sizeof(read_port), FS_DELAY);
  *value = read_port.value;
  return;
}

/* reads digital bit  */
void usbDInBit_USBTC(HIDInterface* hid, __u8 bit_num, __u8* value)
{
  struct t_read_bit {
    __u8 reportID;
    __u8 value;
  } read_bit;

  read_bit.reportID = DBIT_IN;
  read_bit.value = bit_num;

  PMD_SendOutputReport(hid, 0, (__u8*) &read_bit, 2, FS_DELAY);
  usb_interrupt_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &read_bit, sizeof(read_bit), FS_DELAY);
  *value = read_bit.value;
  return;
}

/* writes digital port */
void usbDOut_USBTC(HIDInterface* hid, __u8 value)
{
  struct t_write_port {
    __u8 reportID;
    __u8 value;
  } write_port;

  write_port.reportID = DOUT;
  write_port.value = value;

  PMD_SendOutputReport(hid, 0, (__u8*) &write_port, sizeof(write_port), FS_DELAY);
}

/* writes digital bit  */
void usbDOutBit_USBTC(HIDInterface* hid, __u8 bit_num, __u8 value)
{
  struct t_write_bit {
    __u8 reportID;
    __u8 bit_num;
    __u8 value;
  } write_bit;

  write_bit.reportID = DBIT_OUT;
  write_bit.bit_num = bit_num;
  write_bit.value = value;

  PMD_SendOutputReport(hid, 0, (__u8*) &write_bit, sizeof(write_bit), FS_DELAY);
  return;
}

void usbTin_USBTC(HIDInterface* hid, __u8 channel, __u8 units, float *value)
{

  /*
    This command reads the value from the specified input channel.  The return
    value is a 32-bit floating point value in the units configured fro the
    channel.  CJC readings will always be in Celsius.
  */
  
  struct t_tin {
    __u8 reportID;
    __u8 channel;  // 0 - 7
    __u8 units;    // 0 - temperature, 1 - raw measurement
  } tin;

  struct t_tin_val {
    __u8 reportID;
    __u8 value[4];
  } tin_val;

  tin.reportID = TIN;
  tin.channel = channel;
  tin.units = units;

  PMD_SendOutputReport(hid, 0, (__u8*) &tin, sizeof(tin), FS_DELAY);
  PMD_GetInputReport(hid, 0, (__u8*) &tin_val, sizeof(tin_val), FS_DELAY);
  memcpy(value, tin_val.value, 4);
}

void usbTinScan_USBTC(HIDInterface* hid, __u8 start_chan, __u8 end_chan, __u8 units, float value[])
{
  int nchan;
  struct t_tinScan {
    __u8 reportID;
    __u8 start_chan;  // the first channel to return 0-7 
    __u8 end_chan;    // the last channel to return 0-7
    __u8 units;       // 0 - temperature, 1 - raw measurement
  } tinScan;

  struct t_tinScan_val {
    __u8 reportID;
    __u8 value[32];  // maximum number of measurements 
  } tinScan_val;

  tinScan.reportID = TIN_SCAN;
  tinScan.start_chan = start_chan;
  tinScan.end_chan = end_chan;
  tinScan.units = units;
  nchan = (end_chan - start_chan + 1);

  PMD_SendOutputReport(hid, 0, (__u8*) &tinScan, sizeof(tinScan), FS_DELAY);
  PMD_GetInputReport(hid, 0, (__u8*) &tinScan_val, nchan*sizeof(float)+1, FS_DELAY);
  memcpy(value, tinScan_val.value, nchan*sizeof(float));
}

/* blinks the LED of USB device */
void usbBlink_USBTC(HIDInterface* hid)
{
  __u8 reportID = BLINK_LED;

  PMD_SendOutputReport(hid, 0, &reportID, sizeof(reportID), FS_DELAY);
}

int usbReset_USBTC(HIDInterface* hid)
{
  __u8 reportID = RESET;

  return PMD_SendOutputReport(hid, 0, &reportID, sizeof(reportID), FS_DELAY);
}

__u8 usbGetStatus_USBTC(HIDInterface* hid)
{
  struct t_statusReport {
  __u8 reportID;
  __u8 status;
  } statusReport;

  statusReport.reportID = GET_STATUS;
  PMD_SendOutputReport(hid, 0, &statusReport.reportID, 1, FS_DELAY);
  PMD_GetInputReport(hid, 0, (__u8*) &statusReport, sizeof(statusReport), FS_DELAY);
  return statusReport.status;
}

void usbReadMemory_USBTC(HIDInterface* hid, __u16 address, __u8 type, __u8 count, __u8 *memory)
{
  struct t_readMemory {
    __u8 reportID;
    __u16 address;
    __u8 type;     // 0 = main microcontroller  1 = isolated microcontroller
    __u8 count;
  } readMemory;

  struct t_readMemoryI {
    __u8 reportID;
    __u8 memory[62];
  } readMemoryI;

  if ( count > 62 && type == 0) count = 62;  // 62 bytes max for main microcontroller
  if ( count > 60 && type == 1) count = 60;  // 60 bytes max for isolated microcontroller

  readMemory.reportID = MEM_READ;
  readMemory.type = type;
  readMemory.address = address;
  readMemory.count = count;

  PMD_SendOutputReport(hid, 0, (__u8 *) &readMemory, sizeof(readMemory), FS_DELAY);
  PMD_GetInputReport(hid, 0,  (__u8 *) &readMemoryI, count+1, FS_DELAY);
  memcpy(memory, readMemoryI.memory, count);
}

int usbWriteMemory_USBTC(HIDInterface* hid, __u16 address, __u8 type, __u8 count, __u8* data)
{
  // Locations 0x00-0xFF are available on the main microcontroller
  int i;

  struct t_writeMemory {
    __u8  reportID;
    __u16 address;   // start address for the write (0x00-0xFF)
    __u8  type;      // 0 = main microcontroller  1 = isolated microcontroller
    __u8  count;     // number of bytes to write (59 max)
    __u8  data[count];
  } writeMemory;

  if ( address > 0xff ) return -1;
  if ( count > 59 ) count = 59;

  writeMemory.reportID = MEM_WRITE;
  writeMemory.address = address;
  writeMemory.count = count;
  writeMemory.type = type;

  for ( i = 0; i < count; i++ ) {
    writeMemory.data[i] = data[i];
  }
  PMD_SendOutputReport(hid, 0, (__u8 *) &writeMemory, sizeof(writeMemory), FS_DELAY);
  return 0;
}

void usbSetItem_USBTC(HIDInterface* hid, __u8 item, __u8 subitem, __u32 value)
{
  /*
    This command sets the values of the configuration items.  Because of byte alignment
    issues and the fact that some items take unsigned char and others take floats, two
    structures are used.
  */
    
  struct t_setItem {
    __u8 reportID;
    __u8 item;
    __u8 subitem;
    __u8 value;
  } setItem;

  struct t_setItemFloat {
    __u8 reportID;
    __u8 item;
    __u8 subitem;
    __u8 value[4];
  } setItemFloat;

  switch (subitem) {
    case FILTER_RATE:
    case CH_0_TC:
    case CH_1_TC:
    case CH_0_GAIN:
    case CH_1_GAIN:
      setItem.reportID = SET_ITEM;
      setItem.item = item;
      setItem.subitem = subitem;
      setItem.value = (__u8) value;
      PMD_SendOutputReport(hid, 0,  (__u8 *) &setItem, sizeof(setItem), FS_DELAY);
      break;
    case VREF:
      setItemFloat.reportID = SET_ITEM;
      setItemFloat.item = item;
      setItemFloat.subitem = subitem;
      memcpy(setItemFloat.value, &value, 4);
      PMD_SendOutputReport(hid, 0,  (__u8 *) &setItem, sizeof(setItemFloat), FS_DELAY);
      break;
    default:
      return;
  }
}

int usbGetItem_USBTC(HIDInterface* hid, __u8 item, __u8 subitem, void *value)
{
  __u8 cmd[5];  // The returning data could be one byte or a 4 byte float.
  
  struct t_getItem {
    __u8 reportID;
    __u8 item;
    __u8 subitem;
  } getItem;

  if ( item > 3 ) {
    printf("Error: usbGetItem_USBTC  Item = %d too large.\n", item);
  }

  getItem.reportID = GET_ITEM;
  getItem.item = item;
  getItem.subitem = subitem;

  PMD_SendOutputReport(hid, 0, (__u8 *) &getItem, sizeof(getItem), FS_DELAY);

  switch (subitem) {
    case SENSOR_TYPE:
    case CONNECTION_TYPE:
    case FILTER_RATE:
    case EXCITATION:
    case CH_0_TC:
    case CH_1_TC:
    case CH_0_GAIN:
    case CH_1_GAIN:
      PMD_GetInputReport(hid, 0, cmd, 2, FS_DELAY);
      memcpy(value, &cmd[1], 1);  // one byte value
      return 1;
      break;
    case VREF:
    case I_value_0:
    case I_value_1:
    case I_value_2:
    case V_value_0:
    case V_value_1:
    case V_value_2:
    case CH_0_COEF_0:
    case CH_1_COEF_0:
    case CH_0_COEF_1:
    case CH_1_COEF_1:
    case CH_0_COEF_2:
    case CH_1_COEF_2:
    case CH_0_COEF_3:
    case CH_1_COEF_3:
      PMD_GetInputReport(hid, 0, cmd, 5, FS_DELAY);
      memcpy(value, &cmd[1], 4);
      return 4;
      break;
    default:
      printf("Error usbGetItem_USBTEMP: subitem = %#x unknown\n", subitem);
      return -1;
  }
  return 0;
}


void usbCalibrate_USBTC(HIDInterface* hid)
{
  /*
    The command instructs the device to perform a calibration on all channels.  Used after
    reconfiguring the channel(s).  This may take up to several seconds, and the completion
    may be determined by polling the status with usbGetStatus.  Temperature readings will
    not be updated while the calibration is ongoing, but DIO operations may be performed.
    The device will not accept usbSetItem or usbMemWrite commands while calibration is
    being performed.
  */

  __u8 reportID = CALIBRATE;

  printf("Calibrating.  Please wait ");
  PMD_SendOutputReport(hid, 0, &reportID, 1, FS_DELAY);
  do {
    sleep(1);
    printf(".");
  } while ((usbGetStatus_USBTC(hid) & 0x1) == 1);
  printf("\n");
}

__u8  usbGetBurnoutStatus_USBTC(HIDInterface* hid, __u8 mask)
{
  /*
     This command returns the status of burnout detection for thermocouple channels.  The
     return value is a bitmap indicating the burnout detection status for all 8 channels.
     Individual bits will be set if an open circuit has been detected on that channel.  The
     bits will be cleared after the call using the mask that is passed as a parameter. If
     a bit is set, the corresponding bit in the status will be left at its current value.
  */
 
  struct t_burnoutStatus {
    __u8 reportID;
    __u8 status;
  } burnoutStatus;

  struct t_burnoutStatus_in {
    __u8 reportID;
    __u8 mask;
  } burnoutStatus_in;

  burnoutStatus.reportID = GET_BURNOUT_STATUS;
  burnoutStatus_in.reportID = GET_BURNOUT_STATUS;

  PMD_SendOutputReport(hid, 0, (__u8 *) &burnoutStatus_in, 1, FS_DELAY);
  PMD_GetInputReport(hid, 0, (__u8 *) &burnoutStatus,  sizeof(burnoutStatus), FS_DELAY);
  burnoutStatus_in.mask = mask;
  PMD_SendOutputReport(hid, 0, (__u8 *) &burnoutStatus_in, 2, FS_DELAY);
  return (burnoutStatus.status);
}

void usbPrepareDownload_USBTC(HIDInterface* hid, __u8 micro)
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
    __u8 micro;
  } download;

  download.reportID = PREPARE_DOWNLOAD;
  download.unlock_code = 0xad;
  download.micro = micro; // 0 = main, 1 = isolated
  
  PMD_SendOutputReport(hid, 0,  (__u8 *)  &download, sizeof(download), FS_DELAY);
}

void usbWriteCode_USBTC(HIDInterface* hid, __u32 address, __u8 count, __u8 data[])
{
  /*
    This command writes to the program memory in the device.  This command is not accepted
    unless the device is in update mode.  This command will normally be used when downloading
    a nex hex file, so it supports memory ranges that may be found in the hex file.  The
    microcontroller that is being written to is selected with the "Prepare Download" command.

    The address ranges are:

    0x000000 - 0x0075FF:  Microcontroller FLASH program memory
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

  writecode.reportID = WRITE_CODE;
  memcpy(writecode.address, &address, 3);   // 24 bit address
  writecode.count = count;
  memcpy(writecode.data, data, count);      
  PMD_SendOutputReport(hid, 0, (__u8 *) &writecode, count+5, FS_DELAY);
}

void usbWriteSerial_USBTC(HIDInterface* hid, __u8 serial[8])
{
  // Note: The new serial number will be programmed but not used until hardware reset.
  struct t_writeSerialNumber {
    __u8 reportID;
    __u8 serial[8];
  } writeSerialNumber;

  writeSerialNumber.reportID = WRITE_SERIAL;
  memcpy(writeSerialNumber.serial, serial, 8);
  
  PMD_SendOutputReport(hid, 0, (__u8*) &writeSerialNumber, sizeof(writeSerialNumber), FS_DELAY);
}

int usbReadCode_USBTC(HIDInterface* hid, __u32 address, __u8 count, __u8 data[])
{
  struct t_readCode {
    __u8 reportID;
    __u8 address[3];
    __u8 count;
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
  PMD_SendOutputReport(hid, 0, (__u8 *) &readCode, sizeof(readCode), FS_DELAY);

  bRead = PMD_GetInputReport(hid, 0,  (__u8 *) &readCodeI, count+1, FS_DELAY);
  memcpy(data, readCodeI.data, count);
  return bRead;
}
