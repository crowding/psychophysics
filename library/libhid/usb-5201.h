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

#ifndef USB_5201_H
#define USB_5201_H

#ifdef __cplusplus
extern "C" {
#endif

#define USB5201_PID (0x0098)

#define DIO_DIR_IN  (0x01)
#define DIO_DIR_OUT (0x00)

/* Commands and HID Report ID for USB 5201  */

// Digital I/O Commands
#define DCONFIG     (0x01)     // Configure digital port
#define DCONFIG_BIT (0x02)     // Configure individual digital port bits
#define DIN         (0x03)     // Read digital port
#define DOUT        (0x04)     // Write digital port
#define DBIT_IN     (0x05)     // Read digital port bit
#define DBIT_OUT    (0x06)     // Write digital port bit

#define TIN         (0x18)     // Read input channel
#define TIN_SCAN    (0x19)     // Read multiple input channels

// Memory Commands
#define MEM_READ    (0x30)     // Read Memory
#define MEM_WRITE   (0x31)     // Write Memory

// Miscellaneous Commands
#define BLINK_LED          (0x40) // Causes LED to blink
#define RESET              (0x41) // Reset USB interface
#define GET_STATUS         (0x44) // Get device status
#define SET_ITEM           (0x49) // Set a configuration item
#define GET_ITEM           (0x4A) // Get a configuration item
#define CALIBRATE          (0x4B) // Perform a channel calibration
#define GET_BURNOUT_STATUS (0x4C) // Get thermocouple burnout detection status

// Code Update Commands
#define PREPARE_DOWNLOAD   (0x50) // Prepare for program memory download
#define WRITE_CODE         (0x51) // Write program memory
#define WRITE_SERIAL       (0x53) // Write a new serial number to device
#define READ_CODE          (0x55) // Read program memory

// Data Logging Commands (only valid for USB-5201 and USB-5203)
#define FORMAT_CARD        (0x60) // Format memory card for logging use
#define READ_CLOCK         (0x61) // Read time from device
#define SET_CLOCK          (0x62) // Set device time
#define GET_FIRST_FILE     (0x63) // Get info on first file on volume
#define GET_NEXT_FILE      (0x64) // Get info on next file
#define GET_FILE_INFO      (0x65) // Get info on specified file
#define GET_DISK_INFO      (0x66) // Get information on memory card
#define READ_FILE          (0x67) // Read file from volume
#define DELETE_FILE        (0x68) // Delete File from volume
#define CONFIGURE_LOGGING  (0x69) // Configure data logging feature
#define GET_LOGGING_CONFIG (0x6a) // Read data logging configuration
#define GET_FILE_HEADER    (0x6d) // Read log file header
#define READ_FILE_ACK      (0x6e) // Acknowledge ReadFile data
#define READ_FILE_ABORT    (0x6f) // Abort ReadFile

// Alarm Commands
#define CONFIGURE_ALARM    (0x6b) // Configure temperature alarm
#define GET_ALARM_CONFIG   (0x6c) // Read current temperature alarm configuration

// Channels
#define CH0  (0x0)  // Channel 0
#define CH1  (0x1)  // Channel 1
#define CH2  (0x2)  // Channel 2
#define CH3  (0x3)  // Channel 3
#define CH4  (0x4)  // Channel 4
#define CH5  (0x5)  // Channel 5
#define CH6  (0x6)  // Channel 6
#define CH7  (0x7)  // Channel 7
#define CJC0 (0x80) // Cold Junction Compensator 0
#define CJC1 (0x81) // Cold Junction Compensator 1

// Configuration Items
#define ADC_0 (0x0)  // Setting for ADC 0
#define ADC_1 (0x1)  // Setting for ADC 1
#define ADC_2 (0x2)  // Setting for ADC 2
#define ADC_3 (0x3)  // Setting for ADC 3

// Sub Items
#define SENSOR_TYPE     (0x00) // Sensor type  Read Only
#define CONNECTION_TYPE (0x01) // Connection type - RTD & Thermistor
#define FILTER_RATE     (0x02) // Filter update rate
#define EXCITATION      (0x03) // Currect excitation
#define VREF            (0x04) // Measured Vref value
#define I_value_0       (0x05) // Measured I value @ 10uA
#define I_value_1       (0x06) // Measured I value @ 210uA
#define I_value_2       (0x07) // Measured I value @ 10uA (3 wire connection)
#define V_value_0       (0x08) // Measured V value @ 10uA
#define V_value_1       (0x09) // Measured V value @ 210uA
#define V_value_2       (0x0a) // Measured V value @ 210uA (3 wire connection)
#define CH_0_TC         (0x10) // Thermocouple type for channel 0
#define CH_1_TC         (0x11) // Thermocouple type for channel 1
#define CH_0_GAIN       (0x12) // Channel 0 gain value
#define CH_1_GAIN       (0x13) // Channel 1 gain value
#define CH_0_COEF_0     (0x14) // Coefficient 0
#define CH_1_COEF_0     (0x15) // Coefficient 0
#define CH_0_COEF_1     (0x16) // Coefficient 1
#define CH_1_COEF_1     (0x17) // Coefficient 1
#define CH_0_COEF_2     (0x18) // Coefficient 2
#define CH_1_COEF_2     (0x19) // Coefficient 2
#define CH_0_COEF_3     (0x1a) // Coefficient 3
#define CH_1_COEF_3     (0x1b) // Coefficient 3

// Possible Values
#define RTD           (0x0)
#define THERMISTOR    (0x1)
#define THERMOCOUPLE  (0x2)
#define SEMICONDUCTOR (0x3)
#define DISABLED      (0x4)

#define FREQ_500_HZ   (0x1)
#define FREQ_250_HZ   (0x2)
#define FREQ_125_HZ   (0x3)
#define FREQ_62_5_HZ  (0x4)
#define FREQ_50_HZ    (0x5)
#define FREQ_39_2_HZ  (0x6)
#define FREQ_33_3_HZ  (0x7)
#define FREQ_19_6_HZ  (0x8)
#define FREQ_16_7_HZ  (0x9)
//#define FREQ_16_7_HZ  (0xa)
#define FREQ_12_5_HZ  (0xb)
#define FREQ_10_HZ    (0xc)
#define FREQ_8_33_HZ  (0xd)
#define FREQ_6_25_HZ  (0xe)
#define FREQ_4_17_HZ  (0xf)

#define TYPE_J        (0x0)
#define TYPE_K        (0x1)
#define TYPE_T        (0x2)
#define TYPE_E        (0x3)
#define TYPE_R        (0x4)
#define TYPE_S        (0x5)
#define TYPE_B        (0x6)
#define TYPE_N        (0x7)

#define GAIN_1X       (0x0)
#define GAIN_2X       (0x1)
#define GAIN_4X       (0x2)
#define GAIN_8X       (0x3)
#define GAIN_16X      (0x4)
#define GAIN_32X      (0x5)
#define GAIN_64X      (0x6)
#define GAIN_128X     (0x7)

/* Data Structures */
// Time should always be represented in GMT

typedef struct t_deviceTime {
  __u8 seconds;   // seconds in BCD      range 0-59 (eg 0x25 is 25 seconds)
  __u8 minutes;   // minutes in BCD,     range 0-59
  __u8 hours;     // hours in BCD,       range 0-23 (eg 0x22 is 2200 or 10 pm)
  __u8 day;       // day of month in BCD range 1-31
  __u8 month;     // month in BCD        range 1-12
  __u8 year;      // last 2 digits of year since 2000 in BCD range 0-99  (represents 2000-2099).
  __s8 time_zone; // time zone correction to GMT for local time.
} deviceTime;

// 32-byte structure for FAT16 directory entry structure
typedef struct t_dir_entry {
  char DIR_Name[11];     // Short name.
  __u8 DIR_Attr;         // File attributes
  __u8 DIR_NTRes;        // Reserved for use by Windows NT.  Set value to 0 when
                         // file is created and never modify it afterwards.
  __u8 DIR_CrtTimeTenth; // Millisecond stamp at file creation time.  This field actually
                         // contains a count of tenths of a second.  The granularity of the
                         // second part of DIR_CtrTime is 2 seconds so this field is a
                         // count of tenths of a second and its valid range is 0-199 inclusive.
  __u16 DIR_CtrTime;     // Time file was created.
  __u16 DIR_CrtDate;     // Date file was created.
  __u16 DIR_FstClusHI;   // High word of this entry's first cluster number (always 0)
  __u16 DIR_WrtTime;     // Time of last write. Note that file creation is considered a write.
  __u16 DIRDrtDate;      // Date of lst write. Note that file creation is considered a write.
  __u16 DIRFstClusLO;    // Low word of this entry's first cluster number.
  __u32 DIR_FileSize;    // 32-bit DWORD holding this file's size in bytes.
} dir_entry;

typedef struct t_disk_info {
  __u8 PMD_format;      // Volume formatted for USB-TEMP/TC use
  __u8 Volume_size[4];  // Size of volume in bytes
  __u8 Free_size[4];    // Amount of free space in bytes;
} disk_info;

typedef struct t_file_header {
  __u8 identifier;     // MCC file identifier, 0xDB
  __u8 version;        // Data file version
  __u8 options;        // Logging options
  __u8 channels;       // Channels logged bit mask
  __u8 units;          // Data units bit mask
  __u8 seconds[4];     // Number of seconds between entries
  __u8 start_time[6];  // Time logging started of type deviceTime
} file_header;

/* Status Bits */
#define PERFORMING_CALIBRATION 0x1  // Performing Channel Calibration
#define DAUGHTERBOARD_PRESENT  0x2  // Data logging daughter board present
#define MEMORYCARD_PRESENT     0x4  // Memory card present (can only become set if daughter board is present).
#define READFILE_IN_PROGRESS   0x8  // ReadFile in progress (can be cancelled with ReadFileAbort).

/* Logging Configuration Options */
#define DISABLE      0x0  // disable logging
#define POWER_UP     0x1  // start logging on powerup
#define START_BUTTON 0x2  // start logging on button press
#define START_TIME   0x3  // start logging at specified time
#define LOG_CJC      0x4  // log CJC temperatures
#define LOG_TIME     0x8  // log timestamp on each entry

/* function prototypes for the USB-5201 */
void usbDConfigPort_USB5201(HIDInterface* hid, __u8 direction);
void usbDConfigBit_USB5201(HIDInterface* hid, __u8 bit_num, __u8 direction);
void usbDIn_USB5201(HIDInterface* hid, __u8* value);
void usbDInBit_USB5201(HIDInterface* hid, __u8 bit_num, __u8* value);
void usbDOut_USB5201(HIDInterface* hid, __u8 value);
void usbDOutBit_USB5201(HIDInterface* hid, __u8 bit_num, __u8 value);
void usbTin_USB5201(HIDInterface* hid, __u8 channel, __u8 units, float *value);
void usbTinScan_USB5201(HIDInterface* hid, __u8 start_chan, __u8 end_chan, __u8 units, float value[]);

void usbReadMemory_USB5201(HIDInterface* hid, __u16 address, __u8 type, __u8 count, __u8 memory[]);
int usbWriteMemory_USB5201(HIDInterface* hid, __u16 address, __u8 type, __u8 count, __u8 data[]);
void usbBlink_USB5201(HIDInterface* hid);
int usbReset_USB5201(HIDInterface* hid);
__u8 usbGetStatus_USB5201(HIDInterface* hid);
void usbSetItem_USB5201(HIDInterface* hid, __u8 item, __u8 subitem, __u32 value);
int usbGetItem_USB5201(HIDInterface* hid, __u8 item, __u8 subitem, void* value);
void usbCalibrate_USB5201(HIDInterface* hid);
__u8  usbGetBurnoutStatus_USB5201(HIDInterface* hid, __u8 mask);
void usbPrepareDownload_USB5201(HIDInterface* hid, __u8 micro);
void usbWriteCode_USB5201(HIDInterface* hid, __u32 address, __u8 count, __u8 data[]);
int usbReadCode_USB5201(HIDInterface* hid, __u32 address, __u8 count, __u8 data[]);
void usbWriteSerial_USB5201(HIDInterface* hid, __u8 serial[8]);
void usbGetDeviceTime_USB5201(HIDInterface* hid, deviceTime *date);
void usbSetDeviceTime_USB5201(HIDInterface* hid, deviceTime *date);
void usbFormatCard_USB5201(HIDInterface* hid);
void usbGetFirstFile_USB5201(HIDInterface* hid, dir_entry *dirEntry);
void usbGetNextFile_USB5201(HIDInterface* hid, dir_entry *dirEntry);
void usbGetDiskInfo_USB5201(HIDInterface* hid, disk_info *diskInfo);
void usbGetFileInfo_USB5201(HIDInterface* hid, char *filename, dir_entry *dirEntry);
void usbReadFile_USB5201(HIDInterface* hid, __u8 ack_count, char *filename);
void usbDeleteFile_USB5201(HIDInterface* hid, char *filename);
void usbConfigureLogging_USB5201(HIDInterface* hid, __u8 options, __u8 channels, __u8 units, __u32 seconds,
				 __u16 filenumber, deviceTime starttime);
void usbGetLoggingConfig_USB5201(HIDInterface* hid, __u8 *options, __u8 *channels, __u8 *units, __u32 *seconds,
				 __u16 *filenumber, deviceTime *starttime);
void usbGetFileHeader_USB5201(HIDInterface* hid, char *filename, file_header *header);
void usbReadFileAck_USB5201(HIDInterface* hid);
void usbReadFileAbort_USB5201(HIDInterface* hid);
void usbConfigureAlarm_USB5201(HIDInterface* hid, __u8 number, __u8 in_options, __u8 out_options, float value_1, float value_2);
void usbGetAlarmConfig_USB5201(HIDInterface* hid, __u8 number, __u8 *in_options, __u8 *out_options, float *value_1, float *value_2);

#ifdef __cplusplus
} /* closing brace for extern "C" */
#endif

#endif //USB_5201_H
