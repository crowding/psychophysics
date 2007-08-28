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

#ifndef USB_500_H
#define USB_500_H

#ifdef __cplusplus
extern "C" {
#endif

#include <time.h>

//#define USB_DEBUG

#define USB500_MAX_VALUES (0x4000)   // maximum number of samples 16384

#define USB500_WAIT_READ  500
#define USB500_WAIT_WRITE 100

#define USB500_VID 0x10c4  // Cygnal Integrated Products (Silicon Laboratories)
#define USB500_PID 0x0002  // EL-USB-[1,2]  MCC USB-50[1,2]

#define HIGH_ALARM_STATE (0x1 << 0)     // 1 = High Alarm Enabled, 0 = High Alarm Disabled
#define LOW_ALARM_STATE  (0x1 << 1)     // 1 = Low Alarm Enabled,  0 = Low Alarm Disabled
#define HIGH_ALARM_LATCH (0x1 << 2)     // 1 = High Alarm Indication Hold Enabled
                                        // 0 = High Alarm Indication Hold Disabled
#define LOW_ALARM_LATCH  (0x1 << 3)     // 1 = Low Alarm Indication Hold Enabled                 EL-USB-2 Only
                                        // 0 = Low Alarm Indication Hold Disabled
#define CH2_HIGH_ALARM_STATE (0x1 << 4) // 1 = High Alarm Enabled, 0 = High Alarm Disabled       EL-USB-2 Only
#define CH2_LOW_ALARM_STATE  (0x1 << 5) // 1 = High Alarm Enabled, 0 = High Alarm Disabled       
#define CH2_HIGH_ALARM_LATCH (0x1 << 6) // 1 = High Alarm Indication Hold Enabled                EL-USB-2 Only
                                        // 0 = High Alarm Indication Hold Disabled               
#define CH2_LOW_ALARM_LATCH (0x1 << 7)  // 1 = Low Alarm Indication Hold Enabled                 EL-USB-2 Only
                                        // 0 = Low Alarm Indication Hold Disabled
#define LOGGING_STATE (0x1 << 8)        // 1 = Delayed Start or Logging,  0 = Off
#define UNREAD        (0x1 << 9)        // 1 = Data has NOT been downloaded.
                                        // 0 = Data has been downloaded.
#define BATTERY_LOW   (0x1 << 10)       // 1 = During the last acquistion battery
                                        //     level dropped to a low level 
                                        //     and logging stopped
#define BATTERY_FAIL  (0x1 << 11)       // 1 = During the last acquistion battery
                                        //     level dropped to a critical level 
                                        //     and logging stopped
#define SENSOR_FAIL   (0x1 << 12)       // 1 = During last acquisition there were sensor errors. EL-USB-2 Only

/* 
  Note:
    EL-USB clears after current data has been downloaded.
*/

typedef struct t_configurationBlock {
  unsigned char type;              // 1-3
  unsigned char command;           //
  char name[16];                   // Null terminated
  unsigned char startTimeHours;    // 0-23
  unsigned char startTimeMinutes;  // 0-59
  unsigned char startTimeSeconds;  // 0-59
  unsigned char startTimeDay;      // 1-31
  unsigned char startTimeMonth;    // 1-12
  unsigned char startTimeYear;     // 00-99
  unsigned long startTimeOffset;   // 0-4294967295
  unsigned short sampleRate;       // 0-65535
  unsigned short sampleCount;      // 0-16382
  unsigned short flagBits;         //
  unsigned char highAlarmLevel;    // 0-255
  unsigned char lowAlarmLevel;     // 0-255
  float CalibrationMValue;         // 3.4E +/- 38 (7dig)
  float CalibrationCValue;         // 3.4E +/- 38 (7dig)
  unsigned short rawInputReading;
  unsigned char inputType;         // 0-1
  unsigned char notUsed;
  char version[4];                 // Not Null terminated
  unsigned long serialNumber;      // 0-4294967295
  unsigned char channel2HighAlarm; // 0-255
  unsigned char channel2LowAlarm;  // 0-255
  unsigned char notUsed2[70];
} configurationBlock;

typedef struct t_usb500_data {
  time_t time;         // time sample was taken
  float  temperature;  // temperature
  float  humidity;     // humidity (USB-502 only)
} usb500_data;

float celsius2fahr( float celsius );
float fahr2celsius( float fahr );
void cleanup_USB500( usb_dev_handle *udev );
usb_dev_handle* usb_device_find_USB500( int vendorId, int productId );
void unlock_device_USB500( usb_dev_handle *udev );
void lock_device_USB500(usb_dev_handle *udev);
void read_configuration_block_USB500( usb_dev_handle *udev, configurationBlock *cblock );
void write_configuration_block_USB500( usb_dev_handle *udev, configurationBlock *cblock );
void stop_logging_USB500( usb_dev_handle *udev, configurationBlock *cblock );
void start_logging_USB500( usb_dev_handle *udev, configurationBlock *cblock );
void set_alarm( usb_dev_handle *udev, configurationBlock *cblock );
int read_recorded_data_USB500( usb_dev_handle *udev, configurationBlock *cblock, usb500_data *data );
void write_recorded_data_USB500( configurationBlock *cblock, usb500_data *data );

#ifdef __cplusplus
} /* closing brace for extern "C" */
#endif

#endif //USB_500_H
