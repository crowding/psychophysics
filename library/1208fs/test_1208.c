#include <hid.h>
#include <stdio.h>
#include <string.h>

int main(void) {
    HIDInterface* hid;
    hid_return ret;

    // find the device. This is my USB-1202FS
    HIDInterfaceMatcher matcher = { 0x09DB, 0x0082, NULL, NULL, 0 };

    hid_set_debug(HID_DEBUG_ALL);
    hid_set_debug_stream(stderr);
    hid_set_usb_debug(0);
    
    ret = hid_init();
    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "hid_init failed with return code %d\n", ret);
        return 1;
    }

    hid = hid_new_HIDInterface();
    if (hid == 0) {
        fprintf(stderr, "hid_new_HIDInterface() failed, out of memory?\n");
        return 1;
    }

    ret = hid_force_open(hid, 0, &matcher, 3);
    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "hid_force_open failed with return code %d\n", ret);
        return 1;
    }

    ret = hid_write_identification(stdout, hid);
    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "hid_write_identification failed with return code %d\n", ret);
        return 1;
    }

    ret = hid_dump_tree(stdout, hid);
    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "hid_dump_tree failed with return code %d\n", ret);
        return 1;
    }

    ret = hid_close(hid);
    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "hid_close failed with return code %d\n", ret);
        return 1;
    }

    hid_delete_HIDInterface(&hid);

    ret = hid_cleanup();
    if (ret != HID_RET_SUCCESS) {
        fprintf(stderr, "hid_cleanup failed with return code %d\n", ret);
        return 1;
    }

    return 0;
}
