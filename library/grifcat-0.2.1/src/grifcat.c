/****************************************************************************
 *
 *  $RCSfile: grifcat.c,v $
 *
 *  grifcat - Griffin Powermate cat
 *  Original Author: Caskey Dickson <caskey@technocage.com> 2005-07-09
 *  Copyright 2005 TechnoCage, Inc.  All Rights Reserved
 *  $Id: grifcat.c,v 1.5 2005/08/31 20:04:48 caskey Exp $
 *
 *   This program is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU General Public License
 *   as published by the Free Software Foundation; either version 2
 *   of the License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software Foundation, 
 *   Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 *****************************************************************************/

#include <string.h>
#include <error.h>
#include <stdint.h>
#include <usb.h>
#include <stdio.h>
#include <getopt.h>

#define BUILD 2
#define USB_TIMEOUT  (1*1000)

int VERSION[] = { 0, 2, 1, BUILD };
int verbose = 0;
int debug = 0;
int list_displays_mode = 0;
int cat_mode = 1;
int print_minimal = 0;
int set_brightness_mode = 0;
uint8_t config_brightness = 0;
uint16_t config_pulse = 0;
uint8_t config_pulse_mode = 0;
int enable_pulse_mode = 0;

struct device {
  int vendor;
  int product;
  const char* description;
};


#define GRIFFIN_VENDOR 0x077d

#define GRIFFIN_VENDOR_REQUEST_TYPE 0x41
#define GRIFFIN_VENDOR_REQUEST 0x01

#define SET_STATIC_BRITE 0x01
#define SET_PULSE_ASLEEP 0x02
#define SET_PULSE_AWAKE 0x03
#define SET_PULSE_MODE 0x04

/*
 * The Griffin Powermate has four commands, an interrupt input endpoint
 * plus an interrupt output endpoint.  I have no idea what the output
 * endpoint is for, but it takes 1 byte max.  Beyond that, who knows.
 * 
 * The four commands are used to control the LED in the base.
 * Command 0x01 sets the brightness level used when the LED is not in pulse
 * display mode. (range of 0 to 255)
 * Command 0x02 sets whether or not the led pulses when the host is in
 * sleep mode. (data of 0 or 1)
 * Command 0x03 sets whether or not the led pulses when the system is 
 * awake.  (vs. simply showing the brightness set via command 0x01).
 * Command 0x04 controls the pulsing display.  It has three sub-commands,
 * and takes as a parameter info on how quickly to pulse the led.
 * 0x0004 set pulse mode 0
 * 0x0104 set pulse mode 1
 * 0x0204 set pulse mode 2
 * I have been unable to figure out exactly what each of the pulse modes
 * are, or if the speed value has any effect.
 * 
 * None of the commands use the data portion of the command function.  Instead
 * they use the value and index parameters to pass the command and data
 * respectively.
 * 
 */

struct device devices[] = {
  { GRIFFIN_VENDOR, 0x0410, "Griffin Technology PowerMate" },
  { 0, 0, "User Specified" },
  { 0, 0, NULL },
};

ssize_t userDeviceIndex = (sizeof(devices)/sizeof(struct device)) - 2;

void title() {
  printf(
  "\n"
  " grifcat %d.%d.%d-%d - Griffin Powermate monitor\n"
  "\n"
  "  This utility connects to and streams state change information\n"
  "  of griffin powermate knobs.\n"
  "  Copyright 2005 by TechnoCage, Inc.  All Rights Reserved\n"
  "    <http://www.technocage.com/~caskey/grifcat/>\n"
  "\n"
  , VERSION[0], VERSION[1], VERSION[2], VERSION[3]
  );
  }
void license() {
  title();
  printf(
 "   This program is free software; you can redistribute it and/or\n"
 "   modify it under the terms of the GNU General Public License\n"
 "   as published by the Free Software Foundation; either version 2\n"
 "   of the License, or (at your option) any later version.\n"
 "\n"
 "   This program is distributed in the hope that it will be useful,\n"
 "   but WITHOUT ANY WARRANTY; without even the implied warranty of\n"
 "   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n"
 "   GNU General Public License for more details.\n"
 "\n"
 "   You should have received a copy of the GNU General Public License\n"
 "   along with this program; if not, write to the Free Software Foundation, \n"
 "   Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.\n"
  "\n"
 );
}

void listSupportedDevices() {
  struct device* next = devices;
  ssize_t deviceCount = 0;

  printf("\nSupported Devices:\n\n");
  while(next->description && next->vendor && next->product) {
    deviceCount++;
    printf("  ID:%04x:%04x  %s\n",
      next->vendor, next->product, next->description);
    next++;
  }
  printf("\n %d devices supported\n", deviceCount);
}

void help(const char* program_name) {
  title();
  printf("Usage: %s <options>\n", program_name);
  printf(
  "\n"
  "  --list                 list all the griffin's that can be found\n"
  "                         disables cat mode\n"
  "\n"
  "  --cat                  give full output (default)\n"
  "  --minimal              give minimal output (btn state + direction)\n"
  "\n"
  "  --brightness=n         set led brightness to n (0..255)\n"
  "  --led-off              set led brightness 0\n"
  "  --led-on               set led brightness 255\n"
  "  --led-sync             sync the brightness to the knob rotation\n"
  "  --led-pulse[=n]        turn on pulsing (speed = n 0..511, default 255)\n"
  "  --led-pmode=n          set pulse mode 0,1 or 2\n"
  "\n"
  "  --brief                disable verbose mode (default)\n"
  "  --verbose              extra detail printed\n"
  "  --debug                lots of detail printed (does not set verbose)\n"
  "  --help                 this message\n"
  "  --license              display this software's license\n"
  "\n"
      );
  listSupportedDevices();
}

int parse_argv(int argc, char **argv) {
  static struct option long_options[] = {
    /* These options set a flag. */
    { "verbose", no_argument, &verbose, 1 },
    { "brief",   no_argument, &verbose, 0 },
    { "debug", no_argument, &debug, 1 },

    { "list", no_argument, &list_displays_mode, 1 },
    { "minimal", no_argument, &print_minimal, 1 },
    { "cat", no_argument, &cat_mode, 1 },

    { "help",  no_argument, 0, 'h' },
    { "license",  no_argument, 0, 'l' },

    { "brightness",  required_argument, 0, 'b' },
    { "led-off",  no_argument, 0, 'O' },
    { "led-on",  no_argument, 0, 'o' },
    { "led-pulse",  optional_argument, 0, 'p' },
    { "led-pmode", required_argument, 0, 'M'},

    { "vendor",  required_argument, 0, 'V' },
    { "product",  required_argument, 0, 'P' },

    /* These options don't set a flag.
       We distinguish them by their indices. */
    { 0, 0, 0, 0 }
  };

  for(;;) {
    /* getopt_long stores the option index here. */
    int option_index = 0;
    int c = getopt_long_only(argc, argv, "abc:d:f:h", long_options, &option_index);

    /* Detect the end of the options. */
    if(c == -1) {
      break;
    }

    switch(c) {
      case 0:
        /* If this option set a flag, do nothing else now. */
        if(long_options[option_index].flag != 0) {
          break;
        }
        printf("option %s", long_options[option_index].name);
        if(optarg) {
          printf(" with arg %s", optarg);
        }
        putchar('\n');
        break;
      case 'V':
        devices[userDeviceIndex].vendor = strtol(optarg, 0, 16);
        break;
      case 'P':
        devices[userDeviceIndex].product = strtol(optarg, 0, 16);
        break;

      case 'l':
        license();
        return 0;
        break;
      case 'b':
        set_brightness_mode = 1;
        config_brightness = strtol(optarg, 0, 10);
        cat_mode = 0;
        break;
      case 'o':
        set_brightness_mode = 1;
        config_brightness = 255;
        cat_mode = 0;
        break;
      case 'O':
        set_brightness_mode = 1;
        config_brightness = 0;
        cat_mode = 0;
        break;
      case 'M':
        switch(optarg[0]){
          case '0':
            config_pulse_mode = 0;
            break;
          case '1':
            config_pulse_mode = 1;
            break;
          case '2':
            config_pulse_mode = 2;
            break;
          default:
            fprintf(stderr, "Illegal pulse mode: %c (must be 0..2)\n",optarg[0]);
        }
        enable_pulse_mode=1;
        cat_mode=0;
        break;
      case 'p':
        if(optarg) {
          config_pulse = strtol(optarg, 0, 10);
        } else {
          config_pulse = 255;
        }
        enable_pulse_mode = 1;
        cat_mode = 0;
        break;
      case '?':
      case 'h':
        help(argv[0]);
        return 0;
        break;
      default:
         return 0;
    }
  }

  /* Print any remaining command line arguments (not options). */
  if(optind < argc) {
    printf("Non-option ARGV-elements: ");
    while(optind < argc)
      printf ("%s ", argv[optind++]);
    putchar('\n');
    return 0;
  }

  return 1;
}

int get_dev_control(struct usb_dev_handle* dev, int control,
  uint8_t* data, ssize_t data_len) {
  int ret, value;

  if(debug) {
    printf("Reading 0x%02x\n", control);
  }

  usb_clear_halt(dev, 0x81);

  /* Read the current values */
  ret = usb_control_msg(dev, 
              0xa1,     /* req. type 10100001 == GET_REPORT_REQUEST */
              0x01,     /* request == GET_REPORT */
              value,    /* value  0x0300 = FEATURE & 0x10 = (Brightness)*/
              0,      /* index (interface) */
              (char*)data,  /* bytes */
              data_len,      /* size */
              USB_TIMEOUT); /* timeout 0 = forever*/
  
  if(ret < 0) {
    fprintf(stderr, "Failed to send control message [0x%04x]: %d: %s\n",
        value, ret, strerror(-ret));
    return -1;
  }
  
  if(debug) {
    printf("Read %d bytes [%02x][%02x].\n",
         ret, data[0], data[1]);
  }

  return ret;
}

int set_dev_control(struct usb_dev_handle* dev, int control,
    int value, int index,
    uint8_t* data, ssize_t data_len) {
  int ret;
  
  if(debug) {
    printf("Setting 0x%04x 0x%04x 0x%04x\n", control, value, index);
  }

  /* Read the current values out */
  ret = usb_control_msg(dev, 
      GRIFFIN_VENDOR_REQUEST_TYPE,      /* request type */
      GRIFFIN_VENDOR_REQUEST,           /* request */
      value,
      index,                            /* index (interface) */
      (char*)data,                      /* bytes */
      data_len,                         /* size */
      USB_TIMEOUT);                     /* timeout 0 = forever*/

  if(ret < 0) {
    fprintf(stderr, "Failed to send control message [0x%04x]: %d: %s\n",
        value, ret, strerror(-ret));
    return 0;
  }

  return ret;
}


void set_brite(usb_dev_handle *griffin, uint8_t brite) {
  int ret;
  if(verbose) printf("Trying to set brite %d\n", brite);
  ret = set_dev_control(griffin, 0, SET_STATIC_BRITE, brite, "", 0);
  return;
}

void set_nopulse(usb_dev_handle *griffin) {
  if(verbose) printf("Disabling pulse mode\n");
  set_dev_control(griffin, 0, SET_PULSE_AWAKE, 0, "", 0);
}

void set_pulse(usb_dev_handle *griffin, uint16_t speed) {
  int ret;
  if(verbose) printf("Trying to set pulse speed to %d\n", speed);
  if(speed > 512) speed = 511;
  if(speed < 255) {
    speed = 0x0000 | (0xff-((uint8_t) speed));
  } else if (speed == 255) {
    speed = 0x0100;
  } else {
    speed = 0x0200 | ((uint8_t) speed);
  }
  
  if(debug) printf("Enabling pulse mode\n");
  ret = set_dev_control(griffin, 0, SET_PULSE_AWAKE, 1, "", 0);
  if(debug) printf("Trying to set pulse speed code to %04x\n", speed);
  uint16_t mode = (config_pulse_mode<<8) | SET_PULSE_MODE;
  ret = set_dev_control(griffin, 0, mode,  speed, "", 0);
  return;
}

char *btnnotes[] =  {"BtnUp", "BtnDown"};

void found_device(int index, struct usb_device *dev) {
  int ret;
  usb_dev_handle* griffin_device = usb_open(dev);

  int interface = 0x0;
  if(griffin_device) {
    ret = usb_claim_interface(griffin_device, interface);
    
    if(ret < 0) {
      fprintf(stderr, "Failed to claim interface %d: %s\n", interface, strerror(-ret));
      return;
    }

    if(enable_pulse_mode) {
      set_pulse(griffin_device, config_pulse);
    }

    if(set_brightness_mode) {
      set_nopulse(griffin_device);
      set_brite(griffin_device, config_brightness);
    }
  
    if(list_displays_mode) {
      printf("%04x:%04x %s on USB bus %s device %s \n",
          devices[index].vendor,
          devices[index].product,
          devices[index].description,
          dev->bus->dirname, dev->filename
          );
    } 

    if(cat_mode && !list_displays_mode) {
    uint16_t maxData =  dev->config->interface->altsetting->endpoint->wMaxPacketSize;
    if(debug) printf("Max data size: %d\n", maxData);
    uint8_t data[maxData];
    memset(data, 0, maxData);


    int maxCycles = -1;
    int cycleCounter =0;
    int8_t pos = 0;
    uint32_t cw = 0;
    uint32_t ccw = 0;
    int lastDir = 0;
    int currentBtnState = 0;
    uint32_t transitions[2];
    transitions[0] = transitions[1] = 0;
    /* Read the current values */
    while(maxCycles < 0 || maxCycles--) {
      cycleCounter++;
      ret = usb_interrupt_read(griffin_device, 0x81, data, maxData, 1000000);
      if(ret > 0) {
        if(currentBtnState != data[0]) {
          currentBtnState = data[0];
          transitions[currentBtnState]++;
        }
        if(data[1] == 0x01) {
          pos++;
          cw++;
          lastDir = 1;
        } else if(data[1] == 0xff) {
          pos--;
          ccw++;
          lastDir = -1;
        } else {
          lastDir = 0;
        }
        if(print_minimal) {
          printf("%d %d\n", currentBtnState, lastDir);
          fflush(stderr);
        } else {
          printf("%04x %02x%02x%02x %s %s %d %d %d %u %u %u %u\n"
          , cycleCounter, data[3],data[4],data[5],
              btnnotes[data[0]], lastDir==-1?"Ccw":lastDir==0?"Nc":"Cw"
          , data[0], lastDir, pos, cw, ccw,
              transitions[0], transitions[1]);
          fflush(stderr);
        }
      } else if (ret == 0) {
        if(verbose) fprintf(stderr, "No data read.\n");
      } else if (ret == -110) {
        if(verbose) fprintf(stderr, "Read timeout.\n");
      } else {
        fprintf(stderr, "Failure %d,  %s\n", ret, strerror(-ret));
        goto fail;
      }
    }
    }

fail:
    usb_release_interface(griffin_device, interface);
    usb_close(griffin_device);
  }
}

int main(int argc, char** argv) {
  struct usb_bus* busses;
  struct usb_bus* bus;
  fclose(stdin);

  if(!parse_argv(argc, argv)) return 1;

  if(debug) usb_set_debug(255);

  usb_init();
  usb_find_busses();
  usb_find_devices();
  busses = usb_get_busses();

  if(verbose) {
    fprintf(stderr, "Searching for USB devices ...\n");
  }

  for(bus = busses; bus; bus = bus->next) {
    struct usb_device* dev;
  
    for(dev = bus->devices; dev; dev = dev->next) {
      if(dev->descriptor.bDeviceClass == USB_CLASS_PER_INTERFACE) {
        int i = 0;
        for(; devices[i].vendor && devices[i].product; ++i) {
          if(dev->descriptor.idVendor == devices[i].vendor &&
             dev->descriptor.idProduct == devices[i].product) {
            found_device(i, dev);
          }
        }
      }
    }
  }
    return 0;
}
