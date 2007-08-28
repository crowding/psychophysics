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
//#include <asm/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#include "pmd.h"
#include "usb-1208FS.h"

#define FS_DELAY 2000

enum Mode {Differential, SingleEnded};

/* configures digital port */
void usbDConfigPort_USB1208FS(HIDInterface* hid, __u8 port, __u8 direction)
{
  struct t_config_port {
    __u8 reportID;
    __u8 port;
    __u8 direction;
  } config_port;

  config_port.reportID = DCONFIG;
  config_port.port = port;
  config_port.direction = direction;

  PMD_SendOutputReport(hid, DCONFIG, (__u8*) &config_port, sizeof(config_port), FS_DELAY);
}

/* reads digital port  */
void usbDIn_USB1208FS(HIDInterface* hid, __u8 port, __u8* din_value)
{
  __u8 reportID = DIN;
  int nread;

  struct t_read_port {
    __u8 reportID;
    __u8 value[2];
  } read_port;

  PMD_SendOutputReport(hid, DIN, &reportID, 1, FS_DELAY);
  do {
    read_port.reportID = 0x0;
    nread = usb_bulk_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &read_port, sizeof(read_port), FS_DELAY);
  } while (read_port.reportID != DIN && nread != sizeof(read_port));
  
  /* don't return values off the stack*/
  if (port == DIO_PORTA) {
    *din_value = read_port.value[0];
  } else {
    *din_value = read_port.value[1];
  }
  return;
}

/* writes digital port */
void usbDOut_USB1208FS(HIDInterface* hid, __u8 port, __u8 value)
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

/* writes to analog out */
void usbAOut_USB1208FS(HIDInterface* hid, __u8 channel, __u16 value)
{
  value <<= 0x4;

  struct t_aout {
    __u8 reportID;
    __u8 channel;
    __u8 value[2];
  } aout;

  aout.reportID = AOUT;
  aout.channel = channel;                          // 0 or 1
  aout.value[0] = (__u8) (value & 0xf0);           // low byte
  aout.value[1] = (__u8) ((value >> 0x8) & 0xff);  // high byte

  PMD_SendOutputReport(hid, AOUT, (__u8*) &aout, sizeof(aout), FS_DELAY);
}

int usbAOutScan_USB1208FS(HIDInterface* hid[], __u8 lowchannel, __u8 highchannel,
			  __u32 count, float *frequency, __u16 data[], __u8 options)
{
  int num_samples;
  int nwrite, nread;
  int i,j;
  __u32 preload;
  __u8 byte;
  
  struct t_scanReport {
    __u8 reportID;
    __u8 lowchannel;   // the first channel of the scan
    __u8 highchannel;  // the last channel of the scan
    __u8 count[4];     // the total number of scans to perform
    __u8 prescale;     // timer prescale
    __u8 preload[2];   // timer preload
    __u8 options;      // bit 0: 1 = single execution  0 = continuous
                       // bit 1: 1 = use external trigger
  } scanReport;

  struct t_packet {
    __u8 reportID;
    __u8 data[64];
  } packet;

  if ( highchannel > 1 ) {
    printf("usbAOutScan: highchannel out of range.\n");
    return -1;
  }
  if ( lowchannel > 1 ) {
    printf("usbAOutScan: lowchannel out of range.\n");
    return -1;
  }

  if ( lowchannel > highchannel ) {
    printf("usbAOutScan: lowchannel greater than highchannel.\n");
    return -1;
  }

  num_samples = count*(highchannel - lowchannel + 1);

  scanReport.reportID = AOUT_SCAN;
  scanReport.lowchannel = lowchannel;
  scanReport.highchannel = highchannel;
  scanReport.count[0] = (__u8) count & 0xff;           // low byte
  scanReport.count[1] = (__u8) (count >>  8) & 0xff;
  scanReport.count[2] = (__u8) (count >> 16) & 0xff;
  scanReport.count[3] = (__u8) (count >> 24) & 0xff;   // high byte
  scanReport.options = options;                        // single execution

  packet.reportID = AOUT_SCAN;

  for ( scanReport.prescale = 0; scanReport.prescale <= 8; scanReport.prescale++ ) {
    preload = 10e6/((*frequency) * (1<<scanReport.prescale));
    if ( preload <= 0xffff ) {
      scanReport.preload[0] = (__u8) preload & 0xff;          // low byte
      scanReport.preload[1] = (__u8) (preload >> 8) & 0xff;   // high byte
      break;
    }
  }

  if ( scanReport.prescale == 9 || preload == 0) {
    printf("usbAOutScan_USB1208FS: frequency out of range.\n");
    return -1;
  }
  
  *frequency = 10e6/((1<<scanReport.prescale)*preload);
  //  printf("frequency = %f\n", *frequency);

  /* shift over all data 4 bits */
  for (i = 0; i < num_samples; i++) {
    data[i] <<= 4;
  }
  
  PMD_SendOutputReport(hid[0], AOUT_SCAN, (__u8 *) &scanReport, sizeof(scanReport), FS_DELAY);
  
  i = 0;
  while( num_samples > 0) {
    byte = 0x0;
    do {
      nread = usb_bulk_read(hid[0]->dev_handle, USB_ENDPOINT_IN | 1, (char *)&byte, 1, 30);
    } while ( byte != AOUT_SCAN );
    if ( num_samples >= 32 ) {
      for ( j = 0; j < 64; j += 2 ) {
	packet.data[j] =    data[i] & 0xff;          // low byte
	packet.data[j+1] = (data[i++] >> 8) & 0xff;  // high byte
      }
      packet.reportID = AOUT_SCAN;
      do {
	nwrite = 0x0;
        nwrite = usb_interrupt_write(hid[1]->dev_handle, USB_ENDPOINT_OUT | 2,
				     (char *) &packet, sizeof(packet), 100);
      } while (nwrite != sizeof(packet));
      num_samples -= 32;
    } else {
      for ( j = 0; j < 2*num_samples; j += 2 ) {
	packet.data[j] =    data[i] & 0xff;          // low byte
	packet.data[j+1] = (data[i++] >> 8) & 0xff;  // high byte
      }
      do {
	nwrite = 0x0;
        nwrite = usb_interrupt_write(hid[1]->dev_handle, USB_ENDPOINT_OUT | 2,
				     (char *) &packet, sizeof(packet), 100);
      } while (nwrite != sizeof(packet));
      num_samples = 0;
    }
  }
  return 0;
}

void usbAOutStop_USB1208FS(HIDInterface* hid)
{
  __u8 reportID = AOUT_STOP;
  PMD_SendOutputReport(hid, AOUT_STOP, &reportID, sizeof(reportID), FS_DELAY);  
}

/* reads from analog in */
signed short usbAIn_USB1208FS(HIDInterface* hid, __u8 channel, __u8 range)
{
  enum Mode mode;
  int nread;

  __s16 value;
  __u16 uvalue;
  __u8 report[3];
  
  struct t_ain {
    __u8 reportID;
    __u8 channel;
    __u8 range;
  } ain;

  ain.reportID = AIN;
  ain.channel = channel;
  ain.range = range;
  
  if ( (range == SE_10_00V) && (channel > 7)) {
    mode = SingleEnded;
  } else {
    mode = Differential;
  }

  if (channel > 7 && mode == Differential ) {
    printf("usbAIN: channel out of range for differential mode.\n");
    return -1;
  }

  if (((channel > 15) || (channel < 8)) && (mode == SingleEnded)) {
    printf("usbAIN: channel=%d out of range for single ended mode.\n", channel);
    return -1;
  }

  PMD_SendOutputReport(hid, AIN, (__u8*) &ain, sizeof(ain), FS_DELAY);
  nread = usb_bulk_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
			     (char *) report, sizeof(report), FS_DELAY);
  if (nread != sizeof(ain)) {
    printf("Error in usbAIn_USB1208FS. nread = %d\n", nread);
  }

  if ( mode == Differential ) {
    /* the data is a 2's compliment signed 12 bit number */
    value = (__s16) ( report[1] | (report[2] << 8));
    value /= (1<<4);
  } else {
    /* the data is a  2's compliment signed 11 bit number */
    uvalue = (__u16) ( report[1] | (report[2] << 8));
    if (uvalue > 0x7ff0) {
      uvalue = 0;
    } else if ( uvalue > 0x7fe0 ) {
      uvalue = 0xfff;
    } else {
      uvalue >>= 3;
      uvalue &= 0xfff;
    }
    value = uvalue - 0x800;
  }
  return value;
}

void usbAInStop_USB1208FS(HIDInterface* hid)
{
  __u8 reportID = AIN_STOP;
  PMD_SendOutputReport(hid, AIN_STOP, &reportID, sizeof(reportID), FS_DELAY);
}

int usbAInScan_USB1208FS(HIDInterface* hid[], __u8 lowchannel, __u8 highchannel, __u32 count,
			  float *frequency, __u8 options, __s16 sdata[])
{
  int num_samples;
  int i, j, k;
  int scan_index = 0;
  __u32 preload;

  struct {
    __s16 value[31];
    __u16 scan_index;
  } data;
  
  struct arg {
    __u8 reportID;
    __u8 lowchannel;
    __u8 highchannel;
    __u8 count[4];
    __u8 prescale;
    __u8 preload[2];
    __u8 options;
  } arg;

  if ( highchannel > 7 ) {
    printf("usbAInScan: highchannel out of range.\n");
    return -1;
  }
  if ( lowchannel > 7 ) {
    printf("usbAInScan: lowchannel out of range.\n");
    return -1;
  }
  if (highchannel >= lowchannel) {
    num_samples = count*(highchannel - lowchannel + 1);
  } else {
    num_samples = count*((8-highchannel) + lowchannel + 1);
  }

  arg.reportID = AIN_SCAN;
  arg.lowchannel = lowchannel;
  arg.highchannel = highchannel;
  arg.count[0] = (__u8) count & 0xff;           // low byte
  arg.count[1] = (__u8) (count >>  8) & 0xff;
  arg.count[2] = (__u8) (count >> 16) & 0xff;
  arg.count[3] = (__u8) (count >> 24) & 0xff;   // high byte
  arg.options = options;                        

  for ( arg.prescale = 0; arg.prescale <= 8; arg.prescale++ ) {
    preload = 10e6/((*frequency) * (1<<arg.prescale));
    if ( preload <= 0xffff ) {
      arg.preload[0] = (__u8) preload & 0xff;          // low byte
      arg.preload[1] = (__u8) (preload >> 8) & 0xff;   // high byte
      break;
    }
  }

  *frequency = 10.e6/(preload*(1<<arg.prescale));

  // printf("AInScan: actual frequency = %f\n", *frequency);

  if ( arg.prescale == 9 || preload == 0) {
    printf("usbAInScan_USB1208FS: frequency out of range.\n");
    return -1;
  }
  count = num_samples;  // store value of samples.
  PMD_SendOutputReport(hid[0], AIN_SCAN, (__u8 *) &arg, sizeof(arg), FS_DELAY);
  i = 0;

  while ( num_samples > 0 ) {         
    for ( j = 1; j <= 3; j++ ) {         // cycle through the ADC interfaces/endpoints
      do { 
	usb_bulk_read(hid[j]->dev_handle, USB_ENDPOINT_IN |(j+2),
			   (char *) &data, sizeof(data), FS_DELAY);
      } while (data.scan_index != scan_index);
      scan_index++;

      if ( num_samples > 31 ) {
	for ( k = 0; k < 31;  k++ ) {
          sdata[i+k] = data.value[k];
	}
        num_samples -= 31;
	i += 31;
      } else {   // only copy in a partial scan
	for ( k = 0; k < num_samples;  k++ ) {
          sdata[i+k] = data.value[k];
	}
        num_samples -= 31;
	i += 31;
        break;
      }
      printf("Scan count = %d\tnumber samples left = %d\n", data.scan_index, num_samples);
    }
  }

  // Differential mode: data in 2's compliment signed 12 bit 
  for ( i = 0; i < count; i++ ) {
    sdata[i] /= (1<<4);
  }
  return count;
}

void usbALoadQueue_USB1208FS(HIDInterface* hid, __u8 num, __u8 gains[])
{

  struct t_aLoadQueue {
    __u8 reportID;
    __u8 gains[2*num+1];
  } aLoadQueue;
  int i;

  num = (num <= 8) ? num : 8;

  aLoadQueue.reportID = ALOAD_QUEUE;
  for ( i = 1; i <= 2*num; i++ ) {
    aLoadQueue.gains[i] = gains[i] & 0x7;
  }
  aLoadQueue.gains[0] = num;
  PMD_SendOutputReport(hid, ALOAD_QUEUE, (__u8*) &aLoadQueue, sizeof(aLoadQueue), FS_DELAY);
}

/* Initialize the counter */
void usbInitCounter_USB1208FS(HIDInterface* hid)
{
  __u8 reportID = CINIT;
  PMD_SendOutputReport(hid, CINIT, (__u8*) &reportID, sizeof(reportID), FS_DELAY);
}

__u32 usbReadCounter_USB1208FS(HIDInterface* hid)
{
   __u32 value;
  struct t_counter {
    __u8 reportID;
    __u8 value[4];
  } counter;

  counter.reportID = CIN;

  PMD_SendOutputReport(hid, CIN, (__u8*) &counter, 1, FS_DELAY);
  usb_bulk_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &counter, sizeof(counter), FS_DELAY);
  value =   counter.value[0] | (counter.value[1] << 8) |
    (counter.value[2] << 16) | (counter.value[3] << 24);

  return value;
}

/* blinks the LED of USB device */
void usbBlink_USB1208FS(HIDInterface* hid)
{
  __u8 reportID = BLINK_LED;
  
  PMD_SendOutputReport(hid, BLINK_LED, &reportID, sizeof(reportID), FS_DELAY);
}

int usbReset_USB1208FS(HIDInterface* hid)
{
   __u8 reportID = RESET;

  return PMD_SendOutputReport(hid, RESET, &reportID, sizeof(reportID), FS_DELAY);
}

void usbSetTrigger_USB1208FS(HIDInterface* hid, __u8 type)
{
  __u8 cmd[2];
  
  cmd[0] = SET_TRIGGER;
  cmd[1] = type;
  
  PMD_SendOutputReport(hid, SET_TRIGGER, cmd, sizeof(cmd), FS_DELAY);
}

void usbSetSync_USB1208FS(HIDInterface* hid, __u8 type)
{
  __u8 cmd[2];

  cmd[0] = SET_SYNC;
  cmd[1] = type;
  
  PMD_SendOutputReport(hid, SET_SYNC, cmd, sizeof(cmd), FS_DELAY);
}

__u16 usbGetStatus_USB1208FS(HIDInterface* hid)
{
  __u16 status;
    
  struct t_statusReport {
  __u8 reportID;
  __u8 status[2];
  } statusReport;

  statusReport.reportID = GET_STATUS;

  PMD_SendOutputReport(hid, GET_STATUS, &statusReport.reportID, 1, FS_DELAY);
  do {
    statusReport.reportID = 0;
    usb_bulk_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		       (char *) &statusReport, sizeof(statusReport), FS_DELAY);
  } while (statusReport.reportID != GET_STATUS);
  status = (__u16) (statusReport.status[0] | (statusReport.status[1] << 8));

  return status;
}

void usbReadMemory_USB1208FS( HIDInterface* hid, __u16 address, __u8 count, __u8 memory[])
{
  // Addresses 0x000 - 0x07F are reserved for firmware data
  // Addresses 0x080 - 0x3FF are available for use as calibraion or user data
  struct arg {
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
}

int usbWriteMemory_USB1208FS(HIDInterface* hid, __u16 address, __u8 count, __u8* data)
{
  // Locations 0x00-0x7F are reserved for firmware and my not be written.
  int i;
  struct arg {
    __u8  reportID;
    __u8  address[2];
    __u8  count;
    __u8  data[count];
  } arg;

  if ( address <=0x7f ) return -1;
  if ( count > 59 ) count = 59;

  arg.reportID = MEM_WRITE;
  arg.address[0] = address & 0xff;
  arg.address[1] = (address >> 8) & 0xff;
  arg.count = count;
  for ( i = 0; i < count; i++ ) {
    arg.data[i] = data[i];
  }
  PMD_SendOutputReport(hid, MEM_WRITE, (__u8 *) &arg, sizeof(arg), FS_DELAY);
  return 0;
}

void usbGetAll_USB1208FS(HIDInterface* hid, __u8 data[])
{
  struct t_getAll {
    __u8 reportID;
    __u8 chan0[0];
    __u8 chan1[0];
    __u8 chan2[0];
    __u8 chan3[0];
    __u8 chan4[0];
    __u8 chan5[0];
    __u8 chan6[0];
    __u8 chan7[0];
    __u8 dio_portA;
    __u8 dio_portB;
  } getAll;

  getAll.reportID = GET_ALL;
    
  PMD_SendOutputReport(hid, GET_ALL, &getAll.reportID, 1, FS_DELAY);
  usb_bulk_read(hid->dev_handle, USB_ENDPOINT_IN | 1,
		     (char *) &getAll, sizeof(getAll), FS_DELAY);
}

/* converts signed short value to volts for Single Ended Mode */
float volts_SE( const signed short num )
{
  float volt;
  volt = num * 10.0 / 0x7ff;
  return volt;
}

/* converts signed short value to volts for Differential Mode */     
float volts_FS( const int gain, const signed short num )
{
  float volt;

  switch( gain ) {
    case BP_20_00V:
      volt = num * 20.0 / 0x7ff;
      break;
    case BP_10_00V:
      volt = num * 10.0 / 0x7ff;
      break;
    case BP_5_00V:
      volt = num * 5.0 / 0x7ff;
      break;
    case BP_4_00V:
      volt = num * 4.0 / 0x7ff;
      break;
    case BP_2_50V:
      volt = num * 2.5 / 0x7ff;
      break;
    case BP_2_00V:
      volt = num * 2.0 / 0x7ff;
      break;
    case BP_1_25V:
      volt = num * 1.25 / 0x7ff;
      break;
    case BP_1_00V:
      volt = num * 1.0 / 0x7ff;
      break;
  }
  return volt;
}
