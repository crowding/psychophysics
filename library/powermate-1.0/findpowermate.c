#include <linux/input.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include "findpowermate.h"

#define NUM_VALID_PREFIXES 2

static const char *valid_prefix[NUM_VALID_PREFIXES] = {
  "Griffin PowerMate",
  "Griffin SoundKnob"
};

#define NUM_EVENT_DEVICES 16

int open_powermate(const char *dev, int mode)
{
  int fd = open(dev, mode);
  int i;
  char name[255];

  if(fd < 0){
    fprintf(stderr, "Unable to open \"%s\": %s\n", dev, strerror(errno));
    return -1;
  }

  if(ioctl(fd, EVIOCGNAME(sizeof(name)), name) < 0){
    fprintf(stderr, "\"%s\": EVIOCGNAME failed: %s\n", dev, strerror(errno));
    close(fd);
    return -1;
  }

  // it's the correct device if the prefix matches what we expect it to be:
  for(i=0; i<NUM_VALID_PREFIXES; i++)
    if(!strncasecmp(name, valid_prefix[i], strlen(valid_prefix[i])))
      return fd;

  close(fd);
  return -1;
}

int find_powermate(int mode)
{
  char devname[256];
  int i, r;

  for(i=0; i<NUM_EVENT_DEVICES; i++){
    sprintf(devname, "/dev/input/event%d", i);
    r = open_powermate(devname, mode);
    if(r >= 0)
      return r;
  }

  return -1;
}
