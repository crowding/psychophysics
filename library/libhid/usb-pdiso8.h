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

#ifndef USB_PDISO8_H
#define USB_PDISO8_H

#ifdef __cplusplus
extern "C" { 
#endif 

#define USBPDISO8_PID            (0x008c)
#define USBSWITCH_AND_SENSE_PID  (0x0084)

#define RELAY_PORT      (0x0)
#define ISO_PORT        (0x1)
#define FILTER_PORT     (0x2)
#define DEBUG_PORT      (0x3)
#define DAC_PORT        (0x4)

/* Commands and Codes for USB PDISO8 HID reports */
#define DIN              (0x03) // Read digital port
#define DOUT             (0x04) // Write digital port
#define DBIT_IN          (0x05) // Read Digital port bit
#define DBIT_OUT         (0x06) // Write Digital port bit

#define MEM_READ         (0x30) // Read Memory
#define MEM_WRITE        (0x31) // Write Memory

#define BLINK_LED        (0x40) // Causes LED to blink

#define WRITE_SERIAL     (0x53) // Write new serial number to device


/* function prototypes for the USB-SSR */
__u8 usbDIn_USBPDISO8(HIDInterface* hid, __u8 port);
void usbDOut_USBPDISO8(HIDInterface* hid, __u8 port, __u8 value);
__u8 usbDBitIn_USBPDISO8(HIDInterface* hid, __u8 port, __u8 bit);
void usbDBitOut_USBPDISO8(HIDInterface* hid, __u8 port, __u8 bit, __u8 value);
void usbReadMemory_USBPDISO8(HIDInterface* hid, __u16 address, __u8 count, __u8* memory);
int usbWriteMemory_USBPDISO8(HIDInterface* hid, __u16 address, __u8 count, __u8* data);
void usbBlink_USBPDISO8(HIDInterface* hid);
void usbWriteSerial_USBPDISO8(HIDInterface* hid, __u8 serial[8]);

#ifdef __cplusplus
} /* closing brace for extern "C" */
#endif

#endif //USB_PDISO8_H


