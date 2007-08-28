# This file was created automatically by SWIG.
# Don't modify this file, modify the SWIG interface instead.
# This file is compatible with both classic and new-style classes.

import _hid

def _swig_setattr(self,class_type,name,value):
    if (name == "this"):
        if isinstance(value, class_type):
            self.__dict__[name] = value.this
            if hasattr(value,"thisown"): self.__dict__["thisown"] = value.thisown
            del value.thisown
            return
    method = class_type.__swig_setmethods__.get(name,None)
    if method: return method(self,value)
    self.__dict__[name] = value

def _swig_getattr(self,class_type,name):
    method = class_type.__swig_getmethods__.get(name,None)
    if method: return method(self)
    raise AttributeError,name

import types
try:
    _object = types.ObjectType
    _newclass = 1
except AttributeError:
    class _object : pass
    _newclass = 0
del types



wrap_hid_interrupt_read = _hid.wrap_hid_interrupt_read

wrap_hid_get_input_report = _hid.wrap_hid_get_input_report

wrap_hid_get_feature_report = _hid.wrap_hid_get_feature_report
true = _hid.true
false = _hid.false
HID_RET_SUCCESS = _hid.HID_RET_SUCCESS
HID_RET_INVALID_PARAMETER = _hid.HID_RET_INVALID_PARAMETER
HID_RET_NOT_INITIALISED = _hid.HID_RET_NOT_INITIALISED
HID_RET_ALREADY_INITIALISED = _hid.HID_RET_ALREADY_INITIALISED
HID_RET_FAIL_FIND_BUSSES = _hid.HID_RET_FAIL_FIND_BUSSES
HID_RET_FAIL_FIND_DEVICES = _hid.HID_RET_FAIL_FIND_DEVICES
HID_RET_FAIL_OPEN_DEVICE = _hid.HID_RET_FAIL_OPEN_DEVICE
HID_RET_DEVICE_NOT_FOUND = _hid.HID_RET_DEVICE_NOT_FOUND
HID_RET_DEVICE_NOT_OPENED = _hid.HID_RET_DEVICE_NOT_OPENED
HID_RET_DEVICE_ALREADY_OPENED = _hid.HID_RET_DEVICE_ALREADY_OPENED
HID_RET_FAIL_CLOSE_DEVICE = _hid.HID_RET_FAIL_CLOSE_DEVICE
HID_RET_FAIL_CLAIM_IFACE = _hid.HID_RET_FAIL_CLAIM_IFACE
HID_RET_FAIL_DETACH_DRIVER = _hid.HID_RET_FAIL_DETACH_DRIVER
HID_RET_NOT_HID_DEVICE = _hid.HID_RET_NOT_HID_DEVICE
HID_RET_HID_DESC_SHORT = _hid.HID_RET_HID_DESC_SHORT
HID_RET_REPORT_DESC_SHORT = _hid.HID_RET_REPORT_DESC_SHORT
HID_RET_REPORT_DESC_LONG = _hid.HID_RET_REPORT_DESC_LONG
HID_RET_FAIL_ALLOC = _hid.HID_RET_FAIL_ALLOC
HID_RET_OUT_OF_SPACE = _hid.HID_RET_OUT_OF_SPACE
HID_RET_FAIL_SET_REPORT = _hid.HID_RET_FAIL_SET_REPORT
HID_RET_FAIL_GET_REPORT = _hid.HID_RET_FAIL_GET_REPORT
HID_RET_FAIL_INT_READ = _hid.HID_RET_FAIL_INT_READ
HID_RET_NOT_FOUND = _hid.HID_RET_NOT_FOUND
HID_RET_TIMEOUT = _hid.HID_RET_TIMEOUT
class HIDInterface(_object):
    __swig_setmethods__ = {}
    __setattr__ = lambda self, name, value: _swig_setattr(self, HIDInterface, name, value)
    __swig_getmethods__ = {}
    __getattr__ = lambda self, name: _swig_getattr(self, HIDInterface, name)
    def __repr__(self):
        return "<C HIDInterface instance at %s>" % (self.this,)
    __swig_getmethods__["device"] = _hid.HIDInterface_device_get
    if _newclass:device = property(_hid.HIDInterface_device_get)
    __swig_getmethods__["interface"] = _hid.HIDInterface_interface_get
    if _newclass:interface = property(_hid.HIDInterface_interface_get)
    __swig_getmethods__["id"] = _hid.HIDInterface_id_get
    if _newclass:id = property(_hid.HIDInterface_id_get)
    def __init__(self, *args):
        _swig_setattr(self, HIDInterface, 'this', _hid.new_HIDInterface(*args))
        _swig_setattr(self, HIDInterface, 'thisown', 1)
    def __del__(self, destroy=_hid.delete_HIDInterface):
        try:
            if self.thisown: destroy(self)
        except: pass

class HIDInterfacePtr(HIDInterface):
    def __init__(self, this):
        _swig_setattr(self, HIDInterface, 'this', this)
        if not hasattr(self,"thisown"): _swig_setattr(self, HIDInterface, 'thisown', 0)
        _swig_setattr(self, HIDInterface,self.__class__,HIDInterface)
_hid.HIDInterface_swigregister(HIDInterfacePtr)

class HIDInterfaceMatcher(_object):
    __swig_setmethods__ = {}
    __setattr__ = lambda self, name, value: _swig_setattr(self, HIDInterfaceMatcher, name, value)
    __swig_getmethods__ = {}
    __getattr__ = lambda self, name: _swig_getattr(self, HIDInterfaceMatcher, name)
    def __repr__(self):
        return "<C HIDInterfaceMatcher instance at %s>" % (self.this,)
    __swig_setmethods__["vendor_id"] = _hid.HIDInterfaceMatcher_vendor_id_set
    __swig_getmethods__["vendor_id"] = _hid.HIDInterfaceMatcher_vendor_id_get
    if _newclass:vendor_id = property(_hid.HIDInterfaceMatcher_vendor_id_get, _hid.HIDInterfaceMatcher_vendor_id_set)
    __swig_setmethods__["product_id"] = _hid.HIDInterfaceMatcher_product_id_set
    __swig_getmethods__["product_id"] = _hid.HIDInterfaceMatcher_product_id_get
    if _newclass:product_id = property(_hid.HIDInterfaceMatcher_product_id_get, _hid.HIDInterfaceMatcher_product_id_set)
    def __init__(self, *args):
        _swig_setattr(self, HIDInterfaceMatcher, 'this', _hid.new_HIDInterfaceMatcher(*args))
        _swig_setattr(self, HIDInterfaceMatcher, 'thisown', 1)
    def __del__(self, destroy=_hid.delete_HIDInterfaceMatcher):
        try:
            if self.thisown: destroy(self)
        except: pass

class HIDInterfaceMatcherPtr(HIDInterfaceMatcher):
    def __init__(self, this):
        _swig_setattr(self, HIDInterfaceMatcher, 'this', this)
        if not hasattr(self,"thisown"): _swig_setattr(self, HIDInterfaceMatcher, 'thisown', 0)
        _swig_setattr(self, HIDInterfaceMatcher,self.__class__,HIDInterfaceMatcher)
_hid.HIDInterfaceMatcher_swigregister(HIDInterfaceMatcherPtr)

HID_ID_MATCH_ANY = _hid.HID_ID_MATCH_ANY
HID_DEBUG_NONE = _hid.HID_DEBUG_NONE
HID_DEBUG_ERRORS = _hid.HID_DEBUG_ERRORS
HID_DEBUG_WARNINGS = _hid.HID_DEBUG_WARNINGS
HID_DEBUG_NOTICES = _hid.HID_DEBUG_NOTICES
HID_DEBUG_TRACES = _hid.HID_DEBUG_TRACES
HID_DEBUG_ASSERTS = _hid.HID_DEBUG_ASSERTS
HID_DEBUG_NOTRACES = _hid.HID_DEBUG_NOTRACES
HID_DEBUG_ALL = _hid.HID_DEBUG_ALL

hid_set_debug = _hid.hid_set_debug

hid_set_debug_stream = _hid.hid_set_debug_stream

hid_set_usb_debug = _hid.hid_set_usb_debug

hid_new_HIDInterface = _hid.hid_new_HIDInterface

hid_delete_HIDInterface = _hid.hid_delete_HIDInterface

hid_reset_HIDInterface = _hid.hid_reset_HIDInterface

hid_init = _hid.hid_init

hid_cleanup = _hid.hid_cleanup

hid_is_initialised = _hid.hid_is_initialised

hid_open = _hid.hid_open

hid_force_open = _hid.hid_force_open

hid_close = _hid.hid_close

hid_is_opened = _hid.hid_is_opened

hid_strerror = _hid.hid_strerror

hid_get_input_report = _hid.hid_get_input_report

hid_set_output_report = _hid.hid_set_output_report

hid_get_feature_report = _hid.hid_get_feature_report

hid_set_feature_report = _hid.hid_set_feature_report

hid_get_item_value = _hid.hid_get_item_value

hid_write_identification = _hid.hid_write_identification

hid_dump_tree = _hid.hid_dump_tree

hid_interrupt_read = _hid.hid_interrupt_read

hid_interrupt_write = _hid.hid_interrupt_write

hid_set_idle = _hid.hid_set_idle
_doc = hid_interrupt_read.__doc__
hid_interrupt_read = wrap_hid_interrupt_read
hid_interrupt_read.__doc__ = _doc

_doc = hid_get_input_report.__doc__
hid_get_input_report = wrap_hid_get_input_report
hid_get_input_report.__doc__ = _doc

_doc = hid_get_feature_report.__doc__
hid_get_feature_report = wrap_hid_get_feature_report
hid_get_feature_report.__doc__ = _doc

import sys
hid_return = {}
for sym in dir(sys.modules[__name__]):
    if sym.startswith('HID_RET_'):
        hid_return[eval(sym)] = sym


