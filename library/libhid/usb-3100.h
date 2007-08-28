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

#ifndef USB_31XX_H

#define USB_31XX_H
#ifdef __cplusplus
extern "C" { 
#endif 

#define USB3105_PID (0x009E)
#define USB3106_PID (0x009F)
#define USB3114_PID (0x00A4)

#define DIO_DIR_IN  (0x01)
#define DIO_DIR_OUT (0x00)

#define UP_10_00V 0     /* 0 - 10V      */
#define BP_10_00V 1     /* +/- 10V      */

#define SYNC_MASTER 0
#define SYNC_SLAVE  1

/* Commands and HID Report ID for USB 31XX  */

#define DCONFIG     (0x01)     // Configure digital port
#define DCONFIG_BIT (0x02)     // Configure individual digital port bits
#define DIN         (0x03)     // Read digital port
#define DOUT        (0x04)     // Write digital port
#define DBIT_IN     (0x05)     // Read digital port bit
#define DBIT_OUT    (0x06)     // Write digital port bit

#define AOUT        (0x14)     // Write analog output channel
#define AOUT_SYNC   (0x15)     // Synchronously update outputs
#define AOUT_CONFIG (0x1C)     // Configure analog output channel

#define CINIT       (0x20)     // Initialize counter
#define CIN         (0x21)     // Read Counter

#define MEM_READ    (0x30)     // Read Memory
#define MEM_WRITE   (0x31)     // Write Memory

#define BLINK_LED   (0x40)     // Causes LED to blink
#define RESET       (0x41)     // Reset USB interface
#define SET_SYNC    (0x43)     // Configure sync input/output
#define GET_STATUS  (0x44)     // Get device status

#define PREPARE_DOWNLOAD (0x50) // Prepare for program memory download
#define WRITE_CODE       (0x51) // Write program memory
#define WRITE_SERIAL     (0x53) // Write a new serial number to device

/* function prototypes for the USB-31XX */
void usbDConfigPort_USB31XX(HIDInterface* hid, __u8 direction);
void usbDIn_USB31XX(HIDInterface* hid, __u8* din_value);
void usbDOut_USB31XX(HIDInterface* hid, __u8 value);

void usbAOutConfig_USB31XX(HIDInterface* hid, __u8 channel, __u8 range);
void usbAOut_USB31XX(HIDInterface* hid, __u8 channel, __u16 value, __u8 update);
void usbAOutSync_USB31XX(HIDInterface* hid);

void usbInitCounter_USB31XX(HIDInterface* hid);
__u32 usbReadCounter_USB31XX(HIDInterface* hid);

void usbReadMemory_USB31XX( HIDInterface* hid, __u16 address, __u8 count, __u8* memory);
int usbWriteMemory_USB31XX(HIDInterface* hid, __u16 address, __u8 count, __u8 data[]);
void usbBlink_USB31XX(HIDInterface* hid, __u8 count);
int usbReset_USB31XX(HIDInterface* hid);
__u16 usbGetStatus_USB31XX(HIDInterface* hid);
void usbPrepareDownload_USB31XX(HIDInterface* hid);
int usbWriteCode_USB31XX(HIDInterface* hid, __u32 address, __u8 count, __u8 data[]);
void usbWriteSerial_USB31XX(HIDInterface* hid, __u8 serial[8]);
  
#ifdef __cplusplus
} /* closing brace for extern "C" */
#endif

#endif //USB_31XX_H
