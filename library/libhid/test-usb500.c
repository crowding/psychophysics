#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <time.h>
#include <ctype.h>
#include <math.h>
#include <usb.h>
#include <sys/types.h>
#include <asm/types.h>
#include "usb-500.h"

static unsigned long startTimeOffset = 0;

float celsius2fahr( float celsius )
{
  return (celsius*9.0/5.0 + 32.);
}

float fahr2celsius( float fahr )
{
  return (fahr - 32.)*5.0/9.0;
}

void cleanup_USB500( usb_dev_handle *udev )
{
  if (udev) {
    usb_clear_halt(udev, USB_ENDPOINT_IN|2);
    usb_clear_halt(udev, USB_ENDPOINT_OUT|2);
    usb_release_interface(udev, 0);
    usb_close(udev);
  }
}

usb_dev_handle* usb_device_find_USB500( int vendorId, int productId )
{
  struct usb_bus *bus = NULL;
  struct usb_device *dev = NULL;
  usb_dev_handle *udev = NULL;
  int ret;
  usb_init();
  //  usb_set_debug(3);
  usb_find_busses();
  usb_find_devices();

  for (bus = usb_get_busses(); bus; bus = bus->next) {   // loop through all the busses
    for (dev = bus->devices; dev; dev = dev->next) {     // loop through all the devices
      if ( (dev->descriptor.idVendor == vendorId) &&     // If this is our device ...
           (dev->descriptor.idProduct == productId)) {
	if ((udev = usb_open(dev))) {       // open the device
          printf("Vendor ID = %#x    Product ID = %#x\n", dev->descriptor.idVendor, dev->descriptor.idProduct);
          /* set the configuration */
	  if ((ret = usb_set_configuration(udev, 1))) {
	    perror("Error setting configuration\n");
	  }
          /* claim interface */
	  if ((ret = usb_claim_interface(udev, 0))) {
            perror("Error claiming usb interface 0\n");
	  }
	  return udev;
	}
      }
    }
  }
  return 0;
}

void unlock_device_USB500( usb_dev_handle *udev )
{
  int requesttype = 0x40; // vendor type request
  int request = 0x02;
  int index = 0x0;
  int value = 0x2;
  int size = 0x0;
  char payload[8];
  int timeout = 0;

  usb_control_msg(udev, requesttype, request, value, index, payload, size, timeout);
}

void lock_device_USB500(usb_dev_handle *udev)
{
  int requesttype = 0x40;  // vendor type request
  int request = 0x02;
  int index = 0x0;
  int value = 0x4;
  int size = 0x0;
  char payload[8];
  int timeout = 0;

  usb_control_msg(udev, requesttype, request, value, index, payload, size, timeout);
}

void read_configuration_block_USB500( usb_dev_handle *udev, configurationBlock *cblock )
{
  char request_configuration[3] = {0x00, 0xff, 0xff};  // Request Configuration String
  __u8 acknowledge[3] =           {0x00, 0x00, 0x00};  // Acknowledge string
  unsigned int size = 0;
  int ret;
  int try = 0;

  unlock_device_USB500(udev);

  ret = usb_bulk_write(udev, USB_ENDPOINT_OUT | 2,  request_configuration, 3, USB500_WAIT_WRITE);
  if (ret < 0) {
    perror("Error in requesting configuration (Bulk Write)");
  }

  acknowledge[0] = 0x0;
  do {
    ret = usb_bulk_read(udev, USB_ENDPOINT_IN|2, (char *) acknowledge, 3, USB500_WAIT_READ);
    if ( ret < 0 ) {
      perror("Error in acknowledging configuration from USB 500");
    }
    if (ret == 3 && acknowledge[0] != 0x2) {
      printf("read_configuration_block_USB500: try = %d  first byte = %x\n", try, acknowledge[0]);
      usb_bulk_write(udev, USB_ENDPOINT_OUT | 2,  request_configuration, 3, USB500_WAIT_WRITE);
      try++;
    }
    if (try > 10) {
      printf("read_configuration_block_USB500: try = %d  Stopping now \n", try);
      exit(-1);
    }
  } while (acknowledge[0] != 0x2);

  size = ((acknowledge[2] << 8) | acknowledge[1]);
  do {
    ret = usb_bulk_read(udev, USB_ENDPOINT_IN | 2, (char *) cblock, size, USB500_WAIT_READ);
    if ( ret < 0 ) {
      perror("Error in reading configuration block from USB 500");
    }
  } while (ret != size);

  lock_device_USB500(udev);
}

void write_configuration_block_USB500( usb_dev_handle *udev, configurationBlock *cblock )
{
  __u8 send_configuration[3] = {0x01, 0xff, 0xff}; // Send Configuration String
  __u8 acknowledge = 0x0;                          // Acknowledge 
  unsigned int size = 0;
  int ret;

  /* Determine the size of the Configuration Block */
  switch(cblock->type) {
    case 0x1:                        // EL-USB-1 Temperature Logger Packet size 64 bytes
      send_configuration[1] = 0x40;  // Low Byte
      send_configuration[2] = 0x00;  // High Byte
      size = 64;
      break;
    
    case 0x2:                        // EL-USB-1 Temperature Logger Packet size 64 bytes
      send_configuration[1] = 0x40;  // Low Byte
      send_configuration[2] = 0x00;  // High Byte
      size = 64;
      break;
    
    case 0x3:                        // EL-USB-2 Temperature/Humidity Logger Packet size 128 bytes
      send_configuration[1] = 0x80;  // Low Byte
      send_configuration[2] = 0x00;  // High Byte
      size = 128;
      break;
    
    case 0x4:                        // EL-USB-3 Voltage Logger 256 bytes
      send_configuration[1] = 0x00;  // Low Byte
      send_configuration[2] = 0x01;  // High Byte
      size = 256;
      break;
    
    case 0x5:                        // EL-USB-4 Current Logger 256 bytes
      send_configuration[1] = 0x00;  // Low Byte
      send_configuration[2] = 0x01;  // High Byte
      size = 256;
      break;
    
    case 0x6:                        // EL-USB-3 Voltage Logger 256 bytes
      send_configuration[1] = 0x00;  // High Byte
      send_configuration[2] = 0x01;  // Low Byte
      size = 256;
      break;
    
    case 0x7:                        // EL-USB-4 Current Logger 256 bytes
      send_configuration[1] = 0x00;  // Low Byte
      send_configuration[2] = 0x01;  // High Byte
      size = 256;
      break;

  default:
    printf("Unknown type device = %d\n", cblock->type);
    return;
    break;
  }

  unlock_device_USB500(udev);

  ret = usb_bulk_write(udev, USB_ENDPOINT_OUT | 2,  (char *) send_configuration, 3, USB500_WAIT_WRITE);
  if (ret < 0) {
    perror("Error in sending configuration acknowledgement (Bulk Write)");
  }

  ret = usb_bulk_write(udev, USB_ENDPOINT_OUT | 2,  (char *) cblock, size, USB500_WAIT_WRITE);
  if (ret < 0) {
    perror("Error in sending configuration block (Bulk Write)");
  }

  acknowledge = 0x0;
  do {
    ret = usb_bulk_read(udev, USB_ENDPOINT_IN|2, (char *) &acknowledge, 1, USB500_WAIT_READ);
  } while (acknowledge != 0xff);

  lock_device_USB500(udev);
}

void stop_logging_USB500( usb_dev_handle *udev, configurationBlock *cblock )
{
  read_configuration_block_USB500(udev, cblock);
  cblock->flagBits &= ~(LOGGING_STATE);
  startTimeOffset = cblock->startTimeOffset;
  cblock->startTimeOffset = 0;
  write_configuration_block_USB500(udev, cblock);
}

void start_logging_USB500( usb_dev_handle *udev, configurationBlock *cblock )
{
  time_t currentTime;
  struct tm *tp;

  read_configuration_block_USB500(udev, cblock);
  cblock->flagBits |= (LOGGING_STATE);
  cblock->startTimeOffset = cblock->startTimeOffset;

  time(&currentTime);
  tp = localtime(&currentTime);	
  cblock->startTimeHours = tp->tm_hour;
  cblock->startTimeMinutes = tp->tm_min;
  cblock->startTimeSeconds = tp->tm_sec;
  cblock->startTimeDay = tp->tm_mday;
  cblock->startTimeMonth = tp->tm_mon + 1;    // months from 1-12
  cblock->startTimeYear = tp->tm_year - 100;  // years start from 2000 not 1900.

  write_configuration_block_USB500(udev, cblock);
}

void set_alarm( usb_dev_handle *udev, configurationBlock *cblock )
{
  char ans[80];
  float temperature;
  float humidity;

  read_configuration_block_USB500(udev, cblock);

  printf("Enable High Alarm? [y/n] ");
  scanf("%s", ans);
  if (ans[0] == 'y') {
    cblock->flagBits |= HIGH_ALARM_STATE;
  } else {
    cblock->flagBits &= ~HIGH_ALARM_STATE;
  }

  printf("Enable High Alarm Latch? [y/n] ");
  scanf("%s", ans);
  if (ans[0] == 'y') {
    cblock->flagBits |= HIGH_ALARM_LATCH;
  } else {
    cblock->flagBits &= ~HIGH_ALARM_LATCH;
  }

  if (cblock->flagBits & (HIGH_ALARM_STATE | HIGH_ALARM_LATCH)) {
    printf("Enter High Alarm Level (Temp): ");
    scanf("%f", &temperature);
    cblock->highAlarmLevel = (unsigned char) (temperature - cblock->CalibrationCValue) / cblock->CalibrationMValue;
  }

  printf("Enable Low Alarm? [y/n] ");
  scanf("%s", ans);
  if (ans[0] == 'y') {
    cblock->flagBits |= LOW_ALARM_STATE;
  } else {
    cblock->flagBits &= ~LOW_ALARM_STATE;
  }

  printf("Enable Low Alarm Latch? [y/n] ");
  scanf("%s", ans);
  if (ans[0] == 'y') {
    cblock->flagBits |= LOW_ALARM_LATCH;
  } else {
    cblock->flagBits &= ~LOW_ALARM_LATCH;
  }

  if (cblock->flagBits & (LOW_ALARM_STATE | LOW_ALARM_LATCH)) {
    printf("Enter Low Alarm Level (Temp): ");
    scanf("%f", &temperature);
    cblock->lowAlarmLevel = (unsigned char) (temperature - cblock->CalibrationCValue) / cblock->CalibrationMValue;
  }

  if (cblock->type == 3) {  // USB-502 only
    printf("Enable Channel 2 High Alarm? [y/n] ");
    scanf("%s", ans);
    if (ans[0] == 'y') cblock->flagBits |= CH2_HIGH_ALARM_STATE; 

    printf("Enable Channel 2 High Alarm Latch? [y/n] ");
    scanf("%s", ans);
    if (ans[0] == 'y') cblock->flagBits |= CH2_HIGH_ALARM_LATCH;

    if (cblock->flagBits & (CH2_HIGH_ALARM_STATE | CH2_HIGH_ALARM_LATCH)) {
      printf("Enter Channel 2 High Alarm Level (Humdity): ");
      scanf("%f", &humidity);
      cblock->channel2HighAlarm = (unsigned char) (humidity - 0.0) / 0.5;
    }

    printf("Enable Channel 2 Low Alarm? [y/n] ");
    scanf("%s", ans);
    if (ans[0] == 'y') cblock->flagBits |= CH2_LOW_ALARM_STATE;

    printf("Enable Channel 2 Low Alarm Latch? [y/n] ");
    scanf("%s", ans);
    if (ans[0] == 'y') cblock->flagBits |= CH2_LOW_ALARM_LATCH;

    if (cblock->flagBits & (CH2_LOW_ALARM_STATE | CH2_LOW_ALARM_LATCH)) {
      printf("Enter Channel 2 Low Alarm Level (Humidity): ");
      scanf("%f", &humidity);
      cblock->channel2LowAlarm = (unsigned char) (humidity - 0.0) / 0.5;
    }
  }
  write_configuration_block_USB500(udev, cblock);
}

int read_recorded_data_USB500( usb_dev_handle *udev, configurationBlock *cblock, usb500_data *data )
{
  __u8 request_data[3] = {0x03, 0xff, 0xff};  // Request Recorded Data
  __u8 acknowledge[3] =  {0x00, 0x00, 0x00};  // Acknowledge string
  int packet_size;
  int memory_size;
  int num_packets;
  unsigned int size = 0;
  int ret;
  int i;
  __u8 rdata[0x8000];  // max data size
  struct tm ltime;
  time_t currentTime;

  time(&currentTime);
  localtime_r(&currentTime, &ltime);  // set daylight savings field

  stop_logging_USB500(udev, cblock);  // must stop logging before reading the data.

  switch(cblock->type) {
    case 0x1:                         // EL-USB-1 Temperature Logger Packet size 64 bytes
      packet_size = 64;
      memory_size = 0x4000;
      break;
    
    case 0x2:                         // EL-USB-1 Temperature Logger Packet size 512 bytes
      packet_size = 512;
      memory_size = 0x4000;
      break;
    
    case 0x3:                         // EL-USB-2 Temperature/Humidity Logger Packet size 512 bytes
      packet_size = 512;
      memory_size = 0x8000;
      break;
    
    case 0x4:                         // EL-USB-3 Voltage Logger
    case 0x6:                         // EL-USB-3 Voltage Logger
      packet_size = 512;
      memory_size = 0xfe00;
      break;
    
    case 0x5:                         // EL-USB-4 Current Logger
    case 0x7:                         // EL-USB-4 Current Logger
      packet_size = 512;
      memory_size = 0xfe00;
      break;
    
  default:
    printf("Unknown type device = %d\n", cblock->type);
    return -1;
    break;
  }

  unlock_device_USB500(udev);

  ret = usb_bulk_write(udev, USB_ENDPOINT_OUT | 2,  (char *)request_data, 3, USB500_WAIT_WRITE);
  if (ret < 0) {
    perror("Error in requesting configuration (Bulk Write)");
  }
  do {
    ret = usb_bulk_read(udev, USB_ENDPOINT_IN|2, (char *) acknowledge, 3, USB500_WAIT_READ);
    if ( ret < 0 ) {
      perror("Error in acknowledging read data from USB 500");
    }
  } while (acknowledge[0] != 0x2);

  size = ((acknowledge[2] << 8) | acknowledge[1]);
  if (size != memory_size) {
    printf("Memory Error mismatch. size = %#x  should be %#x\n", size, memory_size);
    return -1;
  }

  num_packets = memory_size / packet_size;
  for ( i = 0; i < num_packets; i++ ) {
    do {
      ret = usb_bulk_read(udev, USB_ENDPOINT_IN | 2, (char *) &rdata[i*packet_size], packet_size, USB500_WAIT_READ);
      if (ret < 0) {
	perror("Error reading data.  Retrying.");
      }
    } while (ret != packet_size);
  }

  lock_device_USB500(udev);

  ltime.tm_sec = cblock->startTimeSeconds;
  ltime.tm_min = cblock->startTimeMinutes;
  ltime.tm_hour = cblock->startTimeHours;
  ltime.tm_mday = cblock->startTimeDay;
  ltime.tm_mon = cblock->startTimeMonth - 1;
  ltime.tm_year = cblock->startTimeYear + 100;
  data[0].time = mktime(&ltime);  // get local time stamp

  for (i = 0; i < cblock->sampleCount; i++) {
    data[i].time = data[0].time + i*cblock->sampleRate;
    if (cblock->type == 3) {
      data[i].temperature = cblock->CalibrationMValue*rdata[2*i] + cblock->CalibrationCValue;  // temperature first byte
      data[i].humidity = 0.5*rdata[2*i+1];                                                     // humidity second byte
    } else {
      data[i].temperature = cblock->CalibrationMValue*rdata[i] + cblock->CalibrationCValue;
    }
  }
  start_logging_USB500(udev, cblock); 
  return cblock->sampleCount;
}


void write_recorded_data_USB500(configurationBlock *cblock, usb500_data *data )
{
  /* Create CVS file to be read into OpenOffice.  When reading file, choose file type as TEXT cvs */
  char filename[80];
  FILE *fp;
  int i;
  float t, logew, dewPoint;
  struct tm ltime;
  char dates[40];
 
  printf("Enter filename: ");
  scanf("%s", filename);
  fp = fopen(filename, "w");
 
  /* Format for USB-501 */
  if (cblock->type == 1) {
    fprintf(fp, "\"Name\",\"%s\"\n", cblock->name);
    fprintf(fp, "\"Serial Number\",\"%ld\"\n", cblock->serialNumber);
    fprintf(fp, "\"Model\",\"USB-501\"\n");

    if (cblock->inputType == 0) {
      fprintf(fp, "\"Sample\",\"Date/Time\",\"Temperature (C)\"\n");
    } else {
      fprintf(fp, "\"Sample\",\"Date/Time\",\"Temperature (F)\"\n");
    }
    for (i = 0; i < cblock->sampleCount; i++) {
      localtime_r(&data[i].time, &ltime);
      strftime(dates, 79, "%D %r", &ltime);
      fprintf(fp,"%5d,%s,%.2f\n", i+1, dates, data[i].temperature);
    }
  }
  /* Format for USB-502 */
  if (cblock->type == 3) {
    fprintf(fp, "\"Name\",\"%s\"\n", cblock->name);
    fprintf(fp, "\"Serial Number\",\"%ld\"\n", cblock->serialNumber);
    fprintf(fp, "\"Model\",\"USB-502\"\n");
    if (cblock->inputType == 0) {
      fprintf(fp, "\"Sample\",\"Date/Time\",\"Temperature (C)\",\"Humidity\",\"Dew point (C)\"\n");
    } else {
      fprintf(fp, "\"Sample\",\"Date/Time\",\"Temperature (F)\",\"Humidity\",\"Dew point (F)\"\n");
    }
    for (i = 0; i < cblock->sampleCount; i++) {
      localtime_r(&data[i].time, &ltime);
      strftime(dates, 79, "%D %r", &ltime);
      if (cblock->inputType == 0) {
	t = data[i].temperature;
      } else {
	t = fahr2celsius(data[i].temperature);
      }
      logew = (0.66077 +(7.5*t/(237.3 + t))) + (log10(data[i].humidity) - 2.0);
      dewPoint = ((0.66077 - logew)*237.3) / (logew - 8.16077);
      if (cblock->inputType == 1) dewPoint = celsius2fahr(dewPoint);
      strftime(dates, 79, "%D %r", &ltime);
      fprintf(fp,"%5d,%s,%.2f,%.1f,%.1f\n", i+1, dates, data[i].temperature, data[i].humidity, dewPoint);
    }
  }
  fclose(fp);
}

int main( void )
{
  usb_dev_handle *udev = NULL;
  configurationBlock cb;
  time_t currentTime;
  struct tm ltime;
  float t, logew, dewPoint;
  int i, j;
  usb500_data data[USB500_MAX_VALUES];
  char dates[40];
  char name[16];
  char ans[80];


  udev = usb_device_find_USB500(USB500_VID, USB500_PID);
  if (udev) {
    printf("Success, found a USB 500!\n");
  } else {
    printf("Failure, did not find a USB 500!\n");
    return 0;
  }

  while (1) {
    printf("1. Status\n");
    printf("2. Configure USB 500 device for logging\n");
    printf("3. Download data\n");
    printf("4. Repair SRAM\n");
    printf("5. Exit\n");
    printf("Please select from 1-5:  \n");

    scanf("%s", ans);
    switch(ans[0]) {
      case '1':
        read_configuration_block_USB500(udev, &cb);
	printf("\n\n");
	switch(cb.type) {
	  case 1:  printf("Device:\t\t\t USB-501 (version 1.6 and earlier)\n"); break;
	  case 2:  printf("Device:\t\t\t USB-501 (version 1.7 and later)\n"); break;
	  case 3:  printf("Device:\t\t\t USB-502\n"); break;
          default: printf("Device:\t\t\t Unkown\n"); break;
	}
	printf("Device Name:\t\t %s\n", cb.name);
	if (cb.flagBits & LOGGING_STATE) {
          if (cb.startTimeOffset == 0) {
	    printf("Status:\t\t\t Logging\n");
	  } else {
	    printf("Status:\t\t\t Delayed Start\n");
            printf("Delay:\t\t\t %ld\n", cb.startTimeOffset);
	  }
	} else {
  	  printf("Status:\t\t\t Off\n");
	}

        ltime.tm_sec = cb.startTimeSeconds;
        ltime.tm_min = cb.startTimeMinutes;
        ltime.tm_hour = cb.startTimeHours;
        ltime.tm_mday = cb.startTimeDay;
        ltime.tm_mon = cb.startTimeMonth - 1;
        ltime.tm_year = cb.startTimeYear + 100;
        strftime(dates, 79, "%m/%d/%Y", &ltime);
	printf("Start Date:\t\t %s\n", dates);
        strftime(dates, 79, "%r", &ltime);
	printf("Start Time:\t\t %s\n", dates);

	printf("Number of Readings:\t %-d\n", cb.sampleCount);
	printf("Sample Interval:\t %d seconds\n", cb.sampleRate);
	if (cb.inputType == 0) { // Celsius
	  printf("Scale:\t\t\t Celsius");
	} else {
	  printf("Scale:\t\t\t Fahrenheit");
	}
        if (cb.type == 3) {
	  printf(", %%rh\n");
	} else {
	  printf("\n");
	}
	if (cb.flagBits & HIGH_ALARM_STATE) {
	  printf("High Alarm:\t\t Enabled\n");
	} else {
	  printf("High Alarm:\t\t Disabled\n");	  
	}
	if (cb.flagBits & LOW_ALARM_STATE) {
	  printf("Low Alarm:\t\t Enabled\n");
	} else {
	  printf("Low Alarm:\t\t Disabled\n");	  
	}
	printf("Serial Number:\t\t %ld\n", cb.serialNumber);
	strncpy(name, cb.version, 4);
	printf("Firmware Version:\t %s\n", name);
	printf("\n\n");
	break;
      case '2':
        stop_logging_USB500(udev, &cb);
        /* initialize the parameter block */

        // sanity check
        printf("cb.type = %d\n", cb.type);
        printf("serial number = %ld\n", cb.serialNumber);
	cb.command = 0x0;
	printf("Device name = \"%s\": ",cb.name);
	tcflush(0, TCIOFLUSH);
	getchar();
	fgets(name, 15, stdin);
	if (name[0] != '\n') {
  	  cb.name[15] = '\0';  // null terminate
	  j = 0;
	  for (i = 0; i < strlen(cb.name); i++) {
	    switch (name[i]) {
	    case '\r':
	    case '\n':
	    case '%':
	    case '&':
	    case '*':
	    case ',':
	    case '.':
	    case '/':
	    case ':':
	    case '<':
	    case '>':
	    case '?':
	    case '\\':
	    case '(':
	    case ')':
	      break;
	    default:
	      cb.name[j++] = name[i];
	    }
	  }
	}

	printf("0 = Celsius, 1 = Fahrenheit: ");
	scanf("%hhd", &cb.inputType);
	if (cb.inputType == 0) { // Celsius
	  cb.CalibrationMValue = 0.5;
	  cb.CalibrationCValue = -40;
	} else {                // Fahrenheit
	  cb.inputType = 1;
	  cb.CalibrationMValue = 1.0;
	  cb.CalibrationCValue = -40;
	}
	
	printf("Enter sample rate [seconds/sample].  Must be > 10:  ");
	scanf("%hd", &cb.sampleRate);
	if (cb.sampleRate < 10) cb.sampleRate = 10;
        write_configuration_block_USB500(udev, &cb);

        /* uncomment to set alarms */
        set_alarm(udev, &cb);
	
        time(&currentTime);
	printf("Setting Device time to: %s and start logging\n", ctime(&currentTime));
        start_logging_USB500(udev, &cb); 
	break;

      case '3':
        read_recorded_data_USB500(udev, &cb, data);

        if (cb.type == 1 || cb.type == 2) {
          printf("\n\nModel: USB-501\n");
          if (cb.inputType == 0) {
	    printf("Sample         Date/Time            Temperature (C) \n");
	  } else {
	    printf("Sample         Date/Time            Temperature (F) \n");
	  }
	  for (i = 0; i < cb.sampleCount; i++) {
            localtime_r(&data[i].time, &ltime);
            strftime(dates, 79, "%D %r", &ltime);
            printf("%5d    %s           %.2f  \n", i+1, dates, data[i].temperature);
	  }
	  printf("\n\n");
          printf("Save to file? [y/n] ");
          scanf("%s", ans);
	  if (ans[0] == 'y') write_recorded_data_USB500(&cb, data);
	}

        if (cb.type == 3) {
          printf("\n\nModel: USB-502\n");
          if (cb.inputType == 0) {
	    printf("Sample         Date/Time            Temperature (C)       Humidity    Dew point (C)\n");
	  } else {
	    printf("Sample         Date/Time            Temperature (F)       Humidity    Dew point (F)\n");
	  }
	  for (i = 0; i < cb.sampleCount; i++) {
            localtime_r(&data[i].time, &ltime);
            if (cb.inputType == 0) {
              t = data[i].temperature;
	    } else {
              t = fahr2celsius(data[i].temperature);
	    }
            logew = (0.66077 +(7.5*t/(237.3 + t))) + (log10(data[i].humidity) - 2.0);
	    dewPoint = ((0.66077 - logew)*237.3) / (logew - 8.16077);
            if (cb.inputType == 1) dewPoint = celsius2fahr(dewPoint);
            strftime(dates, 79, "%D %r", &ltime);
            printf("%5d    %s           %.2f               %.1f        %.1f\n",
		   i+1, dates, data[i].temperature, data[i].humidity, dewPoint);
	  }
	  printf("\n\n");
          printf("Save to file? [y/n] ");
          scanf("%s", ans);
	  if (ans[0] == 'y') write_recorded_data_USB500(&cb, data);
	}
	break;
      case '4':
        printf("******* WARNING*******\n");
        printf("Only proceed if your device is not working.\n");
        printf("Do you want to proceed? [y/n]");
        scanf("%s", ans);
        if (ans[0] == 'n') break;
        /* get the serial number and software version */
        read_configuration_block_USB500(udev, &cb);
        printf("    1. USB-501 version 1.6 and earlier.\n");
        printf("    2. USB-501 version 1.7 and later.\n");
        printf("    3. USB-502\n");
        printf("Enter your Device type [1-3]: \n");
        scanf("%hhd", &cb.type);
       	strncpy(cb.name, "EasyLog USB", 15);
	// strncpy(cb.version, "v2.0", 4);
        cb.inputType = 1;
        cb.command = 0x0;
        cb.CalibrationMValue = 1.0;
	cb.CalibrationCValue = -40;
        cb.sampleRate = 60;
        cb.flagBits = 0x0;
        time(&currentTime);
        localtime_r(&currentTime, &ltime);	
        cb.startTimeHours = ltime.tm_hour;
        cb.startTimeMinutes = ltime.tm_min;
	cb.startTimeSeconds = ltime.tm_sec;
	cb.startTimeDay = ltime.tm_mday;
	cb.startTimeMonth = ltime.tm_mon + 1;    // months from 1-12
	cb.startTimeYear = ltime.tm_year - 100;  // years start from 2000 not 1900.
        cb.highAlarmLevel = 0x0;
        cb.lowAlarmLevel = 0x0;
        write_configuration_block_USB500(udev, &cb);
	break;
      case '5':
	printf("Remove unit from USB port.\n");
	cleanup_USB500(udev);
        return 0;
        break;
    }
  }
}

