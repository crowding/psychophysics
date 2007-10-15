"""
Multi-Platform Python wrapper that implements functions from the LabJack 
Windows UD Driver, and the LabJack Linux and Mac drivers.

B{Author:} LabJack Corporation

B{Version:} 0.61

B{For use with drivers:}
    - Windows UD driver: 2.69
    - Linux driver: 1.1
    - Mac driver: 1.0


This python wrapper is intended to be used as an easy way to implement the 
Windows UD driver, the Mac driver or the Linux driver.  It uses the module ctypes 
to interface with the appropriate operating system LabJack driver.  For versions 
of Python older than 2.4 and older, CTypes is available at 
U{http://sourceforge.net/projects/ctypes/}.  Python 2.5 and new comes with the ctypes
module as a standard.

B{Version History:}
    - B{0.1:} Converted many UD functions to Python using ctyes package.
    - B{0.2:} Made linux support for Open, Read, Write, and driverVersion.
    - B{0.3:} Made Mac support for Open, Read, Write, and driverVersion.
    - B{0.4:} Wrote initial epydoc documentation.
    - B{0.5:} December 12, 2006
        - Added Get Driver Version for Linux
        - Made windows functions return an error when called by a Linux or Mac OS.
        - Fixed a twos compliment problem with Read and Write functions
    - B{0.51:} January 8, 2007
        - Fixed an error with eGetRaw which disallowed x1 to be a double array.
        - Added a stream example program to the driver package.
    - B{0.52:} January 23, 2007
        - Added a DriverPresent function to test if the necessary drivers are present for the wrapper to run.
    - B{0.60:} Febuary 6, 2007
        - Added the LJHash function which is used for authorizing LabJack devices.
    - B{0.61:} July 19, 2007
        - Updated the documentation concerning the mac support. 
"""

import ctypes
import os
import struct
from decimal import Decimal

if(os.name != 'nt'):
    import socket

#Class for handling UE9 TCP Connections
class _UE9TCPHandle:
    """Handles the sockets for a UE9.
    
    Creates two sockets for the streaming and non streaming port on the UE9.  
    Currently only works on default ports.
    
    For Linux and Mac
    """
    def __init__(self):
        self.portA = 52360
        self.portB = 52361
        socket.setdefaulttimeout(1.5)
        self.socketA = socket.socket()
        self.socketB = socket.socket()

class LabJackException(Exception):
    """Custom Exception meant for dealing specifically with LabJack Exceptions.

    Error codes are either going to be a LabJackUD error code or a -1.  The -1 implies
    a python wrapper specific error.
    """
    errorCode = 0
    errorString = ''

    def __init__(self, ec = 0, errorString = ''):
        self.errorCode = ec
        self.errorString = errorString

        if not self.errorString:
            opSys = os.name
            if(opSys == 'nt'):
                pString = ctypes.create_string_buffer(256)
                self.libcc = ctypes.windll.LoadLibrary("labjackud")
                self.libcc.ErrorToString(ctypes.c_long(self.errorCode), ctypes.byref(pString))
                self.errorString = pString.value
            else:
                if(self.errorString == ''):
                    self.errorString = str(self.errorCode)
    
    def __str__(self):
          return self.errorString


class LabJackPython:
    """Multi-Platform Python wrapper that implements functions from the LabJack
    Windows UD Driver, and the LabJack Linux and Mac drivers.

    Most functions with in this Wrapper do not return error codes, but instead raise
    custom LabJack Exceptions.
    """
    
    def __init__(self): 
        pass

    #Windows
    def ListAll(DeviceType, ConnectionType):
        """List All LabJack devices of a specific type over a specific connection type.

        Sample Usage:

        >>> LabJackPython.ListAll(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB)
        (2, [310020231, 310020091], [1, 1], [0.0, 0.0])

        @type  DeviceType: number
        @param DeviceType: The LabJack device.
        @type  ConnectionType: number
        @param ConnectionType: The connection method (Ethernet/USB).
        
        @rtype: Tuple
        @return: The tuple (numFound, serialNumbers, ids, addresses)
            - numFound (number)
            - serialNumber (List)
            - ids (List)
            - addresses (List)
            
        @raise LabJackException: 
        """
        if(os.name == 'nt'):
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pNumFound = ctypes.c_long()
            pSerialNumbers = (ctypes.c_long * 128)()
            pIDs = (ctypes.c_long * 128)()
            pAddresses = (ctypes.c_double * 128)()
    
            #The actual return variables so the user does not have to use ctypes
            serialNumbers = []
            ids = []
            addresses = []
    
            ec = staticLib.ListAll(DeviceType, ConnectionType, 
                                   ctypes.byref(pNumFound), 
                                   ctypes.cast(pSerialNumbers, ctypes.POINTER(ctypes.c_long)), 
                                   ctypes.cast(pIDs, ctypes.POINTER(ctypes.c_long)), 
                                   ctypes.cast(pAddresses, ctypes.POINTER(ctypes.c_long)))
    
            if ec != 0: raise LabJackException(ec)
            for i in range(pNumFound.value):
                serialNumbers.append(pSerialNumbers[i])
                ids.append(pIDs[i])
                addresses.append(pAddresses[i])
            
            return pNumFound.value, serialNumbers, ids, addresses
        else:
            raise LabJackException(0, "Function only supported for Windows")
    ListAll = staticmethod(ListAll)
    
    #Windows Only
    @staticmethod
    def ListAllS(pDeviceType, pConnectionType):
        """List All LabJack devices of a specific type over a specific connection type.

        Sample Usage:

        >>> LabJackPython.ListAll("LJ_dtU3", "LJ_ctUSB")
        (2, [310020231, 310020091], [1, 1], [0.0, 0.0])

        @type  DeviceType: String
        @param DeviceType: The LabJack device.
        @type  ConnectionType: String
        @param ConnectionType: The connection method (Ethernet/USB).
        
        @rtype: Tuple
        @return: The tuple (numFound, serialNumbers, ids, addresses)
            - numFound (number)
            - serialNumber (List)
            - ids (List)
            - addresses (List)
            
        @raise LabJackException: 
        """
        if(os.name == 'nt'):
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pNumFound = ctypes.c_long()
            pSerialNumbers = (ctypes.c_long * 128)()
            pIDs = (ctypes.c_long * 128)()
            pAddresses = (ctypes.c_double * 128)()
    
            #The actual return variables so the user does not have to use ctypes
            serialNumbers = []
            ids = []
            addresses = []
    
            ec = staticLib.ListAllS(pDeviceType, pConnectionType, 
                                    ctypes.byref(pNumFound), 
                                    ctypes.cast(pSerialNumbers, ctypes.POINTER(ctypes.c_long)), 
                                    ctypes.cast(pIDs, ctypes.POINTER(ctypes.c_long)), 
                                    ctypes.cast(pAddresses, ctypes.POINTER(ctypes.c_long)))
            
            if ec != 0: raise LabJackException(ec)
            for i in range(pNumFound.value):
                serialNumbers.append(pSerialNumbers[i])
                ids.append(pIDs[i])
                addresses.append(pAddresses[i])
            
            return pNumFound.value, serialNumbers, ids, addresses
        else:
           raise LabJackException(0, "Function only supported for Windows") 

    #Windows, Linux, and Mac
    def OpenLabJack(DeviceType, ConnectionType, pAddress, FirstFound):
        """Open a LabJack Device.

        If OpenLabJack is called on a machine running Linux or Mac OS X and 
        the DeviceType is a UE9 and the ConnectionType is Ethernet then the 
        Handle will be of type _UE9TCPHandle instead of Long.  All calls to 
        valid Linux and Mac functions will be able to accept this type as a
        valid handle and so the user need not change call calls to those 
        functions accordingly.
        
        Any open device must be closed if using the mac drivers before the
        process that opened it is finished.  If not then the device may be
        held open and become unaaccessible by other processes.
        
        For Windows, Linux, and Mac
        
        Sample Usage:
        
        >>> LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "1", 1)
        12796480
        
        @type  DeviceType: number
        @param DeviceType: The LabJack device.
        @type  ConnectionType: number
        @param ConnectionType: The connection method (Ethernet/USB).
        @type  pAddress: String
        @param pAddress: Address of the LabJack device
        @type  FirstFound: number
        @param FirstFound: 1 to open the first found LabJack, 0 Otherwise.
        
        @rtype: number
        @return: The handle of the opened device
            - handle
        
        @raise LabJackException:
        """

        opSys = os.name
        devType = ctypes.c_ulong(DeviceType)
        staticLib = None
        s = None

        #If windows operating system then use the UD Driver
        if(opSys == 'nt'):
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            handle = ctypes.c_long()
            ec = staticLib.OpenLabJack(DeviceType, ConnectionType, 
                                        pAddress, FirstFound, ctypes.byref(handle))
    
            if ec != 0: raise LabJackException(ec)
            return handle.value

        #If Unix/Linux operating system then do the following
        if(opSys == 'posix'):
            #If the connection type is USB then 
            #If firstFound = False iterate over all labJacks plugged in
            #And open the one with the address = localid
            #Return Handle
            if(ConnectionType == LabJackPython.LJ_ctUSB):
                try:
                    staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.so")
                except:
                    try:
                        staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.dylib")
                    except:
                        raise LabJackException(0, "Could not load library")
                
                addr = ctypes.c_uint(int(pAddress))
                handle = None
                numDevices = staticLib.LJUSB_GetDevCount(devType.value)
                openDev = staticLib.LJUSB_OpenDevice
                openDev.restype = ctypes.c_void_p
                
                for i in range(1, numDevices+1):
                    if(FirstFound == 1):
                        handle = openDev(1, 0, devType)
                        break
                        
                    if(devType.value == LabJackPython.LJ_dtUE9):
                        handle = openDev(i, 0, devType)
                        sndDataBuff = [0] * 38
                        sndDataBuff[0] = 0x89
                        sndDataBuff[1] = 0x78
                        sndDataBuff[2] = 0x10
                        sndDataBuff[3] = 0x01
                        
                        try:
                            LabJackPython.Write(handle, sndDataBuff, 38)
                            readBytes, rcvDataBuff = LabJackPython.Read(handle, 0, 38) 
                        except LabJackException:
                            LabJackPython.CloseDevice(handle)
                            raise LabJackException(1007, "")
                        
                        localID = rcvDataBuff[8] & 0xff
                        if(localID == addr.value):
                            return handle
                    
                    #Perform a comm config to acquire the local id 
                    #Verify if the local id is the same as the sent id and return the handle
                    elif(devType.value == LabJackPython.LJ_dtU3):
                        handle = openDev(i, 0, devType)
                        sndDataBuff = [0] * 26
                        sndDataBuff[0] = 0x0b
                        sndDataBuff[1] = 0xf8
                        sndDataBuff[2] = 0x0a
                        sndDataBuff[3] = 0x08
                        
                        try:
                            LabJackPython.Write(handle, sndDataBuff, 26)
                            readBytes, rcvDataBuff = LabJackPython.Read(handle, 0, 38) 
                        except LabJackException:
                            LabJackPython.CloseDevice(handle)
                            raise LabJackException(LabJackPython.LJE_LABJACK_NOT_FOUND, "")
                        
                        localID = rcvDataBuff[21] & 0xff
                        if(localID == addr.value):
                            return handle
                    
                    LabJackPython.CloseDevice(handle)
                    handle = None
                    
                if(handle==None):
                    raise LabJackException(LabJackPython.LJE_LABJACK_NOT_FOUND, "LabJack not found")
                return handle
        if(ConnectionType == LabJackPython.LJ_ctETHERNET):
            try:
                s = _UE9TCPHandle()
                s.socketA.connect((pAddress, s.portA))
                s.socketB.connect((pAddress, s.portB))
                return s
            except Exception, e:
                if(s):
                    LabJackPython.CloseDevice(s)
                raise LabJackException(LabJackPython.LJE_LABJACK_NOT_FOUND, "LabJack not found at address:" + pAddress)
            
    OpenLabJack = staticmethod(OpenLabJack)

    
    #Not working 
    #Need to convert the string pDeviceType and pConnectionType to numbers to make it work
    def OpenLabJackS(pDeviceType, pConnectionType, pAddress, FirstFound):
        """Open a LabJackDevice.
        
        Function not yet implemented.
        
        For Windows only.
        """
        pass
    OpenLabJackS = staticmethod(OpenLabJackS)

    def AddRequest(Handle, IOType, Channel, Value, x1, UserData):
        """Add a request to the LabJackUD request stack
        
        For Windows
        
        Sample Usage to get the AIN value from channel 0:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequest(u3Handle,LabJackPython.LJ_ioGET_AIN, 0, 0.0, 0, 0.0)
        >>> LabJackPython.Go()
        >>> value = LabJackPython.GetResult(u3Handle, LabJackPython.LJ_ioGET_AIN, 0)
        >>> print "Value:" + str(value)
        Value:0.36582420161
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  IOType: number
        @param IOType: IO Request to the LabJack.
        @type  Channel: number
        @param Channel: Channel for the IO request.
        @type  Value: number
        @param Value: Used for some requests
        @type  x1: number
        @param x1: Used for some requests
        @type  UserData: number
        @param UserData: Used for some requests
        
        @rtype: None
        @return: Function returns nothing.
        
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            
            v = ctypes.c_double(Value)
            ud = ctypes.c_double(UserData)
            
            ec = staticLib.AddRequest(Handle, IOType, Channel, v, x1, ud)
            if ec != 0: raise LabJackException(ec)
        else:
           raise LabJackException(0, "Function only supported for Windows")
    AddRequest = staticmethod(AddRequest)

    #Windows
    def AddRequestS(Handle, pIOType, Channel, Value, x1, UserData):
        """Add a request to the LabJackUD request stack
        
        For Windows
        
        Sample Usage to get the AIN value from channel 0:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequestS(u3Handle,"LJ_ioGET_AIN", 0, 0.0, 0, 0.0)
        >>> LabJackPython.Go()
        >>> value = LabJackPython.GetResult(u3Handle, LabJackPython.LJ_ioGET_AIN, 0)
        >>> print "Value:" + str(value)
        Value:0.366420765873
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  IOType: String
        @param IOType: IO Request to the LabJack.
        @type  Channel: number
        @param Channel: Channel for the IO request.
        @type  Value: number
        @param Value: Used for some requests
        @type  x1: number
        @param x1: Used for some requests
        @type  UserData: number
        @param UserData: Used for some requests
        
        @rtype: None
        @return: Function returns nothing.
        
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            
            v = ctypes.c_double(Value)
            ud = ctypes.c_double(UserData)
            
            ec = staticLib.AddRequestS(Handle, pIOType, Channel, 
                                        v, x1, ud)
    
            if ec != 0: raise LabJackException(ec)
        else:
           raise LabJackException(0, "Function only supported for Windows")
    AddRequestS = staticmethod(AddRequestS)

    #Windows
    def AddRequestSS(Handle, pIOType, pChannel, Value, x1, UserData):
        """Add a request to the LabJackUD request stack
        
        For Windows
        
        Sample Usage to get the AIN value from channel 0:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequestSS(u3Handle,"LJ_ioGET_CONFIG", "LJ_chFIRMWARE_VERSION", 0.0, 0, 0.0)
        >>> LabJackPython.Go()
        >>> value = LabJackPython.GetResultS(u3Handle, "LJ_ioGET_CONFIG", LabJackPython.LJ_chFIRMWARE_VERSION)
        >>> print "Value:" + str(value)
        Value:1.27
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  IOType: String
        @param IOType: IO Request to the LabJack.
        @type  Channel: String
        @param Channel: Channel for the IO request.
        @type  Value: number
        @param Value: Used for some requests
        @type  x1: number
        @param x1: Used for some requests
        @type  UserData: number
        @param UserData: Used for some requests
        
        @rtype: None
        @return: Function returns nothing.
        
        @raise LabJackException:
        """
        if os.name == 'nt':      
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            
            v = ctypes.c_double(Value)
            ud = ctypes.c_double(UserData)
            
            ec = staticLib.AddRequestSS(Handle, pIOType, pChannel, 
                                         v, x1, ud)
    
            if ec != 0: raise LabJackException(ec)
        else:
           raise LabJackException(0, "Function only supported for Windows")
    AddRequestSS = staticmethod(AddRequestSS)

    #Windows
    def Go():
        """Complete all requests currently on the LabJackUD request stack

        For Windows Only
        
        Sample Usage:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequestSS(u3Handle,"LJ_ioGET_CONFIG", "LJ_chFIRMWARE_VERSION", 0.0, 0, 0.0)
        >>> LabJackPython.Go()
        >>> value = LabJackPython.GetResultS(u3Handle, "LJ_ioGET_CONFIG", LabJackPython.LJ_chFIRMWARE_VERSION)
        >>> print "Value:" + str(value)
        Value:1.27
        
        @rtype: None
        @return: Function returns nothing.
        
        @raise LabJackException:
        """
        
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")           
            ec = staticLib.Go()
    
            if ec != 0: raise LabJackException(ec)
        else:
           raise LabJackException(0, "Function only supported for Windows")
    Go = staticmethod(Go)


    #Windows
    def GoOne(Handle):
        """Performs the next request on the LabJackUD request stack
        
        For Windows Only
        
        Sample Usage:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequestSS(u3Handle,"LJ_ioGET_CONFIG", "LJ_chFIRMWARE_VERSION", 0.0, 0, 0.0)
        >>> LabJackPython.GoOne(u3Handle)
        >>> value = LabJackPython.GetResultS(u3Handle, "LJ_ioGET_CONFIG", LabJackPython.LJ_chFIRMWARE_VERSION)
        >>> print "Value:" + str(value)
        Value:1.27
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        
        @rtype: None
        @return: Function returns nothing.
        
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")           
            ec = staticLib.GoOne(Handle)
    
            if ec != 0: raise LabJackException(ec)
        else:
           raise LabJackException(0, "Function only supported for Windows")
    GoOne = staticmethod(GoOne)

    #Windows
    def eGet(Handle, IOType, Channel, pValue, x1):
        """Perform one call to the LabJack Device
        
        eGet is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage:
        
        >>> LabJackPython.eGet(u3Handle, LabJackPython.LJ_ioGET_AIN, 0, 0, 0)
        0.39392614550888538
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  IOType: number
        @param IOType: IO Request to the LabJack.
        @type  Channel: number
        @param Channel: Channel for the IO request.
        @type  Value: number
        @param Value: Used for some requests
        @type  x1: number
        @param x1: Used for some requests
        
        @rtype: number
        @return: Returns the value requested.
            - value
            
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pv = ctypes.c_double(pValue)
            #ppv = ctypes.pointer(pv)
            ec = staticLib.eGet(Handle, IOType, Channel, ctypes.byref(pv), x1)
            #ctypes.eGet.argtypes = [ctypes.c_long, ctypes.c_long, ctypes.c_long, ctypes.c_double, ctypes.c_long]
            #ec = staticLib.eGet(Handle, IOType, Channel, ppv, x1)
            
            if ec != 0: raise LabJackException(ec)
            #print "EGet:" + str(ppv)
            #print "Other:" + str(ppv.contents)
            return pv.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    eGet = staticmethod(eGet)


    #Windows
    #Raw method -- Used because x1 is an output
    #TODO Make call Write
    def eGetRaw(Handle, IOType, Channel, pValue, x1):
        """Perform one call to the LabJack Device as a raw command
        
        eGetRaw is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage (Calling a echo command):
        
        >>> sendBuff = [0] * 2
        >>> sendBuff[0] = 0x70
        >>> sendBuff[1] = 0x70
        >>> LabJackPython.eGetRaw(ue9Handle, LabJackPython.LJ_ioRAW_OUT, 0, len(sendBuff), sendBuff)
        (2.0, [112, 112])
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  IOType: number
        @param IOType: IO Request to the LabJack.
        @type  Channel: number
        @param Channel: Channel for the IO request.
        @type  pValue: number
        @param Value: Length of the buffer.
        @type  x1: number
        @param x1: Buffer to send.
        
        @rtype: Tuple
        @return: The tuple (numBytes, returnBuffer)
            - numBytes (number)
            - returnBuffer (List)
            
        @raise LabJackException:
        """
        ec = 0
        x1Type = "int"
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")

            digitalConst = [35, 36, 37, 45]
            pv = ctypes.c_double(pValue)
    
            #If IOType is digital then call eget with x1 as a long
            if IOType in digitalConst:
                ec = staticLib.eGet(Handle, IOType, Channel, ctypes.byref(pv), x1)
            else: #Otherwise as an array
                
                try:
                    #Verify x1 is an array
                    if len(x1) < 1:
                        raise LabJackException(0, "x1 is not a valid variable for the given IOType") 
                except Exception:
                    raise LabJackException(0, "x1 is not a valid variable for the given IOType")  
                
                #Initialize newA
                newA = None
                if type(x1[0]) == int:
                    newA = (ctypes.c_byte*len(x1))()
                    for i in range(0, len(x1), 1):
                        newA[i] = ctypes.c_byte(x1[i])
                else:
                    x1Type = "float"
                    newA = (ctypes.c_double*len(x1))()
                    for i in range(0, len(x1), 1):
                        newA[i] = ctypes.c_double(x1[i])

                ec = staticLib.eGet(Handle, IOType, Channel, ctypes.byref(pv), ctypes.byref(newA))
                x1 = [[]] * len(x1)
                for i in range(0, len(x1), 1):
                    x1[i] = newA[i]
                    if(x1Type == "int"):
                        x1[i] = x1[i] & 0xff
                
            if ec != 0: raise LabJackException(ec)
            return pv.value, x1
        else:
           raise LabJackException(0, "Function only supported for Windows")
    eGetRaw = staticmethod(eGetRaw)

    #Windows
    def eGetS(Handle, pIOType, Channel, pValue, x1):
        """Perform one call to the LabJack Device
        
        eGet is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage:
        
        >>> LabJackPython.eGet(u3Handle, "LJ_ioGET_AIN", 0, 0, 0)
        0.39392614550888538
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  pIOType: String
        @param pIOType: IO Request to the LabJack.
        @type  Channel: number
        @param Channel: Channel for the IO request.
        @type  Value: number
        @param Value: Used for some requests
        @type  x1: number
        @param x1: Used for some requests
        
        @rtype: number
        @return: Returns the value requested.
            - value
            
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pv = ctypes.c_double(pValue)
            ec = staticLib.eGetS(Handle, pIOType, Channel, ctypes.byref(pv), x1)
    
            if ec != 0: raise LabJackException(ec)
            return pv.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    eGetS = staticmethod(eGetS)

    #Windows
    def eGetSS(Handle, pIOType, pChannel, pValue, x1):
        """Perform one call to the LabJack Device
        
        eGet is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage:
        
        >>> LabJackPython.eGetSS(u3Handle,"LJ_ioGET_CONFIG", "LJ_chFIRMWARE_VERSION", 0, 0)
        1.27
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  pIOType: String
        @param pIOType: IO Request to the LabJack.
        @type  Channel: String
        @param Channel: Channel for the IO request.
        @type  Value: number
        @param Value: Used for some requests
        @type  x1: number
        @param x1: Used for some requests
        
        @rtype: number
        @return: Returns the value requested.
            - value
            
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pv = ctypes.c_double(pValue)
            ec = staticLib.eGetSS(Handle, pIOType, pChannel, ctypes.byref(pv), x1)
    
            if ec != 0: raise LabJackException(ec)
            return pv.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    eGetSS = staticmethod(eGetSS)


    #Windows
    #Not currently implemented
    def eGetRawS(Handle, pIOType, Channel, pValue, x1):
        """Function not yet implemented.
        
        For Windows only.
        """
        pass
    eGetRawS = staticmethod(eGetRawS)

    #Windows
    def ePut(Handle, IOType, Channel, Value, x1):
        """Put one value to the LabJack device
        
        ePut is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.eGet(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chLOCALID, 0, 0)
        0.0
        >>> LabJackPython.ePut(u3Handle, LabJackPython.LJ_ioPUT_CONFIG, LabJackPython.LJ_chLOCALID, 8, 0)
        >>> LabJackPython.eGet(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chLOCALID, 0, 0)
        8.0
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  IOType: number
        @param IOType: IO Request to the LabJack.
        @type  Channel: number
        @param Channel: Channel for the IO request.
        @type  Value: number
        @param Value: Used for some requests
        @type  x1: number
        @param x1: Used for some requests
        
        @rtype: None
        @return: Function returns nothing.
        
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pv = ctypes.c_double(Value)
            ec = staticLib.ePut(Handle, IOType, Channel, pv, x1)
    
            if ec != 0: raise LabJackException(ec)
        else:
           raise LabJackException(0, "Function only supported for Windows")
    ePut = staticmethod(ePut)

    #Windows
    def ePutS(Handle, pIOType, Channel, Value, x1):
        """Put one value to the LabJack device
        
        ePut is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.eGet(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chLOCALID, 0, 0)
        0.0
        >>> LabJackPython.ePutS(u3Handle, "LJ_ioPUT_CONFIG", LabJackPython.LJ_chLOCALID, 8, 0)
        >>> LabJackPython.eGet(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chLOCALID, 0, 0)
        8.0
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  IOType: String
        @param IOType: IO Request to the LabJack.
        @type  Channel: number
        @param Channel: Channel for the IO request.
        @type  Value: number
        @param Value: Used for some requests
        @type  x1: number
        @param x1: Used for some requests
        
        @rtype: None
        @return: Function returns nothing.
        
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            
            pv = ctypes.c_double(Value)
            ec = staticLib.ePutS(Handle, pIOType, Channel, pv, x1)
    
            if ec != 0: raise LabJackException(ec)
        else:
           raise LabJackException(0, "Function only supported for Windows")
    ePutS = staticmethod(ePutS)

    #Windows
    def ePutSS(Handle, pIOType, pChannel, Value, x1):
        """Put one value to the LabJack device
        
        ePut is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.eGet(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chLOCALID, 0, 0)
        0.0
        >>> LabJackPython.ePutSS(u3Handle, "LJ_ioPUT_CONFIG", "LJ_chLOCALID", 8, 0)
        >>> LabJackPython.eGet(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chLOCALID, 0, 0)
        8.0
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  IOType: String
        @param IOType: IO Request to the LabJack.
        @type  Channel: String
        @param Channel: Channel for the IO request.
        @type  Value: number
        @param Value: Used for some requests
        @type  x1: number
        @param x1: Used for some requests
        
        @rtype: None
        @return: Function returns nothing.
        
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
    
            pv = ctypes.c_double(Value)
            ec = staticLib.ePutSS(Handle, pIOType, pChannel, pv, x1)
    
            if ec != 0: raise LabJackException(ec)
        else:
           raise LabJackException(0, "Function only supported for Windows")
    ePutSS = staticmethod(ePutSS)

    #Windows
    def GetResult(Handle, IOType, Channel):
        """Put one value to the LabJack device
        
        ePut is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequestSS(u3Handle,"LJ_ioGET_CONFIG", "LJ_chFIRMWARE_VERSION", 0.0, 0, 0.0)
        >>> LabJackPython.GoOne(u3Handle)
        >>> value = LabJackPython.GetResult(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chFIRMWARE_VERSION)
        >>> print "Value:" + str(value)
        Value:1.27
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  IOType: number
        @param IOType: IO Request to the LabJack.
        @type  Channel: number
        @param Channel: Channel for the IO request.
        
        @rtype: number
        @return: The value requested.
            - value
            
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pv = ctypes.c_double()
            ec = staticLib.GetResult(Handle, IOType, Channel, ctypes.byref(pv))
    
            if ec != 0: raise LabJackException(ec)          
            return pv.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    GetResult = staticmethod(GetResult)

    #Windows
    def GetResultS(Handle, pIOType, Channel):
        """Put one value to the LabJack device
        
        ePut is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequestSS(u3Handle,"LJ_ioGET_CONFIG", "LJ_chFIRMWARE_VERSION", 0.0, 0, 0.0)
        >>> LabJackPython.GoOne(u3Handle)
        >>> value = LabJackPython.GetResultS(u3Handle, "LJ_ioGET_CONFIG", LabJackPython.LJ_chFIRMWARE_VERSION)
        >>> print "Value:" + str(value)
        Value:1.27
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  pIOType: String
        @param pIOType: IO Request to the LabJack.
        @type  Channel: number
        @param Channel: Channel for the IO request.
        
        @rtype: number
        @return: The value requested.
            - value
            
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pv = ctypes.c_double()
            ec = staticLib.GetResultS(Handle, pIOType, Channel, ctypes.byref(pv))
    
            if ec != 0: raise LabJackException(ec)          
            return pv.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    GetResultS = staticmethod(GetResultS)

    #Windows
    def GetResultSS(Handle, pIOType, pChannel):
        """Put one value to the LabJack device
        
        ePut is equivilent to an AddRequest followed by a GoOne.
        
        For Windows Only
        
        Sample Usage:
        
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequestSS(u3Handle,"LJ_ioGET_CONFIG", "LJ_chFIRMWARE_VERSION", 0.0, 0, 0.0)
        >>> LabJackPython.GoOne(u3Handle)
        >>> value = LabJackPython.GetResultSS(u3Handle, "LJ_ioGET_CONFIG", "LJ_chFIRMWARE_VERSION")
        >>> print "Value:" + str(value)
        Value:1.27
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device.
        @type  pIOType: String
        @param pIOType: IO Request to the LabJack.
        @type  Channel: String
        @param Channel: Channel for the IO request.
        
        @rtype: number
        @return: The value requested.
            - value
            
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pv = ctypes.c_double()
            ec = staticLib.GetResultS(Handle, pIOType, pChannel, ctypes.byref(pv))
    
            if ec != 0: raise LabJackException(ec)          
            return pv.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    GetResultSS = staticmethod(GetResultSS)

    #Windows
    def GetFirstResult(Handle):
        """List All LabJack devices of a specific type over a specific connection type.

        For Windows only.

        Sample Usage (Shows getting the localID (8) and firmware version (1.27) of a U3 device):

        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequest(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chLOCALID, 0, 0, 0)
        >>> LabJackPython.AddRequest(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chFIRMWARE_VERSION, 0, 0, 0)
        >>> LabJackPython.Go()
        >>> LabJackPython.GetFirstResult(u3Handle)
        (1001, 0, 8.0, 0, 0.0)
        >>> LabJackPython.GetNextResult(u3Handle)
        (1001, 11, 1.27, 0, 0.0)

        @type  DeviceType: number
        @param DeviceType: The LabJack device.
        @type  ConnectionType: number
        @param ConnectionType: The connection method (Ethernet/USB).
        
        @rtype: Tuple
        @return: The tuple (ioType, channel, value, x1, userData)
            - ioType (number): The io of the result.
            - serialNumber (number): The channel of the result.
            - value (number): The requested result.
            - x1 (number):  Used only in certain requests.
            - userData (number): Used only in certain requests.
            
        @raise LabJackException: 
        """   
        if os.name == 'nt':     
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pio = ctypes.c_long()
            pchan = ctypes.c_long()
            pv = ctypes.c_double()
            px = ctypes.c_long()
            pud = ctypes.c_double()
            ec = staticLib.GetFirstResult(Handle, ctypes.byref(pio), 
                                           ctypes.byref(pchan), ctypes.byref(pv), 
                                           ctypes.byref(px), ctypes.byref(pud))
    
            if ec != 0: raise LabJackException(ec)          
            return pio.value, pchan.value, pv.value, px.value, pud.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    
    GetFirstResult = staticmethod(GetFirstResult)

    #Windows
    def GetNextResult(Handle):
        """List All LabJack devices of a specific type over a specific connection type.

        For Windows only.

        Sample Usage (Shows getting the localID (8) and firmware version (1.27) of a U3 device):

        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.AddRequest(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chLOCALID, 0, 0, 0)
        >>> LabJackPython.AddRequest(u3Handle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chFIRMWARE_VERSION, 0, 0, 0)
        >>> LabJackPython.Go()
        >>> LabJackPython.GetFirstResult(u3Handle)
        (1001, 0, 8.0, 0, 0.0)
        >>> LabJackPython.GetNextResult(u3Handle)
        (1001, 11, 1.27, 0, 0.0)

        @type  DeviceType: number
        @param DeviceType: The LabJack device.
        @type  ConnectionType: number
        @param ConnectionType: The connection method (Ethernet/USB).
        
        @rtype: Tuple
        @return: The tuple (ioType, channel, value, x1, userData)
            - ioType (number): The io of the result.
            - serialNumber (number): The channel of the result.
            - value (number): The requested result.
            - x1 (number):  Used only in certain requests.
            - userData (number): Used only in certain requests.
            
        @raise LabJackException: 
        """ 
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pio = ctypes.c_long()
            pchan = ctypes.c_long()
            pv = ctypes.c_double()
            px = ctypes.c_long()
            pud = ctypes.c_double()
            ec = staticLib.GetNextResult(Handle, ctypes.byref(pio), 
                                           ctypes.byref(pchan), ctypes.byref(pv), 
                                           ctypes.byref(px), ctypes.byref(pud))
    
            if ec != 0: raise LabJackException(ec)          
            return pio.value, pchan.value, pv.value, px.value, pud.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    GetNextResult = staticmethod(GetNextResult)
    
    #Windows, Linux, Mac
    def ResetLabJack(Handle):
        """Reset the LabJack device with the given handle.

        For Windows, Linux, and Mac

        Sample Usage:

        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.ResetLabJack(u3Handle)
        
        @type  Handle: number
        @param Handle: Handle to the LabJack device
        
        @rtype: None
        @return: Function returns nothing.
            
        @raise LabJackException: 
        """        
        
        
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            ec = staticLib.ResetLabJack(Handle)

            if ec != 0: raise LabJackException(ec)
        elif os.name == 'posix':
            sndDataBuff = [0] * 4
            
            #Make the reset packet
            sndDataBuff[0] = 0x9B
            sndDataBuff[1] = 0x99
            sndDataBuff[2] = 0x02
            
            try:
                LabJackPython.Write(Handle, sndDataBuff, 4)
                rcvBytes, rcvDataBuff = LabJackPython.Read(Handle, 0, 4)
                if(rcvBytes != 4):
                    raise LabJackException(0, "Unable to reset labJack 2")
            except:
                raise LabJackException(0, "Unable to reset labjack")
    ResetLabJack = staticmethod(ResetLabJack)


    #Windows
    def DoubleToStringAddress(number):
        """Converts a number (base 10) to an IP string.
        
        For Windows

        Sample Usage:

        >>> LabJackPython.DoubleToStringAddress(3232235985)
        '192.168.1.209'
        
        @type  number: number
        @param number: Number to be converted.
        
        @rtype: String
        @return: The IP string converted from the number (base 10).
            
        @raise LabJackException: 
        """ 
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            b = ctypes.create_string_buffer(16)
            ec = staticLib.DoubleToStringAddress(ctypes.c_double(number), 
                                                  b, 0)
    
            if ec != 0: raise LabJackException(ec)          
            return b.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    DoubleToStringAddress = staticmethod(DoubleToStringAddress)

    #Windows
    def StringToDoubleAddress(pString):
        """Converts an IP string to a number (base 10).

        For Windows

        Sample Usage:

        >>> LabJackPython.StringToDoubleAddress("192.168.1.209")
        3232235985.0
        
        @type  pString: String
        @param pString: String to be converted.
        
        @rtype: number
        @return: The number (base 10) that represents the IP string.
            
        @raise LabJackException: 
        """         
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pNumber = ctypes.c_double()
            a = ctypes.create_string_buffer(pString, len(pString))
            ec = staticLib.StringToDoubleAddress(a, ctypes.byref(pNumber), 0)
    
            if ec != 0: raise LabJackException(ec)          
            return pNumber.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    StringToDoubleAddress = staticmethod(StringToDoubleAddress)

    #Windows
    def StringToConstant(pString):
        """Converts an LabJackUD valid string to its constant value.

        For Windows

        Sample Usage:

        >>> LabJackPython.StringToConstant("LJ_dtU3")
        3
        
        @type  pString: String
        @param pString: String to be converted.
        
        @rtype: number
        @return: The number (base 10) that represents the LabJackUD string.
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            a = ctypes.create_string_buffer(pString, 256)
            return staticLib.StringToConstant(a)
        else:
           raise LabJackException(0, "Function only supported for Windows")
    StringToConstant = staticmethod(StringToConstant)

    #Windows
    def ErrorToString(ErrorCode):
        """Converts an LabJackUD valid error code to a String.

        For Windows

        Sample Usage:

        >>> LabJackPython.ErrorToString(1007)
        'LabJack not found'
        
        @type  ErrorCode: number
        @param ErrorCode: Valid LabJackUD error code.
        
        @rtype: String
        @return: The string that represents the valid LabJackUD error code
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pString = ctypes.create_string_buffer(256)
            staticLib.ErrorToString(ctypes.c_long(ErrorCode), ctypes.byref(pString))
            return pString.value
        else:
           raise LabJackException(0, "Function only supported for Windows")
    ErrorToString = staticmethod(ErrorToString)

    #Windows, Linux, and Mac
    def GetDriverVersion():
        """Converts an LabJackUD valid error code to a String.

        For Windows, Linux, and Mac

        Sample Usage:

        >>> LabJackPython.GetDriverVersion()
        2.64
        
        >>> LabJackPython.GetDriverVersion()
        Mac
        
        @rtype: number/String
        @return: Value of the driver version as a String
            - For Mac machines the return type is "Mac"
            - For Windows and Linux systems the return type is a number that represents the driver version
        """
        
        if os.name == 'nt':        
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            staticLib.GetDriverVersion.restype = ctypes.c_float
            return str(staticLib.GetDriverVersion())
            
        elif os.name == 'posix':
            staticLib = None
            mac = 0
            try:
                staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.so")
            except:
                try:
                    staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.dylib")
                    mac = 1
                except:
                    raise LabJackException("Get Driver Version function could not load library")

            #If not windows then return the operating system.
            if mac:
                return "Mac"
            staticLib.LJUSB_GetLibraryVersion.restype = ctypes.c_float
	        #Return only two decimal places
            twoplaces = Decimal(10) ** -2
            return str(Decimal(str(staticLib.LJUSB_GetLibraryVersion())).quantize(twoplaces))
    GetDriverVersion = staticmethod(GetDriverVersion)
            
    #Windows
    @staticmethod
    def TCVoltsToTemp(TCType, TCVolts, CJTempK):
        """Converts a thermo couple voltage reading to an appropriate temperature reading.

        For Windows

        Sample Usage:

        >>> LabJackPython.TCVoltsToTemp(LabJackPython.LJ_ttK, 0.003141592, 297.038889)
        373.13353222244825
                
        @type  TCType: number
        @param TCType: The type of thermo couple used.
        @type  TCVolts: number
        @param TCVolts: The voltage reading from the thermo couple
        @type  CJTempK: number
        @param CJTempK: The cold junction temperature reading in Kelvin
        
        @rtype: number
        @return: The thermo couples temperature reading
            - pTCTempK
            
        @raise LabJackException:
        """
        if os.name == 'nt':
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            pTCTempK = ctypes.c_double()
            ec = staticLib.TCVoltsToTemp(ctypes.c_long(TCType), ctypes.c_double(TCVolts), 
                                         ctypes.c_double(CJTempK), ctypes.byref(pTCTempK))
    
            if ec != 0: raise LabJackException(ec)          
            return pTCTempK.value
        else:
           raise LabJackException(0, "Function only supported for Windows")


    #Windows 
    def Close():
        """Resets the driver and closes all open handles.

        For Windows

        Sample Usage:

        >>> LabJackPython.Close()
                
        @rtype: None
        @return: The function returns nothing.
        """    
    
        opSys = os.name
        
        if(opSys == 'nt'):
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            staticLib.Close()
        else:
           raise LabJackException(0, "Function only supported for Windows")
    Close = staticmethod(Close)

    #Linux, Mac, Windows
    def CloseDevice(Handle):
        """Closes a specific device with the given handle.

        For Windows, Linux, and Mac
        
        This function is not specifically supported in the LabJackUD driver
        for Windows and as such simply calls the function Close.  For Mac
        drivers, the Close device must be performed when finished with a device.
        The reason for this is because there can not be more than one program
        with a given device open at a time.  If a device is not closed before
        the program is finished it may still be held open and unable to be used
        by other programs until properly closed.

        Sample Usage:

        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "1", 1)
        >>> LabJackPython.CloseDevice(u3Handle)
        
        @type  Handle: number
        @param Handle: Handle of the device to be closed.
                
        @rtype: None
        @return: The function returns nothing.
        
        @raise LabJackException:
        """
        opSys = os.name
        if(opSys == 'posix'):
            if(isinstance(Handle, _UE9TCPHandle)):
                if(Handle.socketA):
                    Handle.socketA.close()
                if(Handle.socketB):
                    Handle.socketB.close()
            else:    
                staticLib = None
                handlePointer = ctypes.c_void_p(Handle)
                try:
                    staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.so")
                except:
                    try:
                        staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.dylib")
                    except:
                        raise LabJackException("Write Buffer function could not load library")
                
                staticLib.LJUSB_CloseDevice(handlePointer);

        if(opSys == 'nt'):
            staticLib = ctypes.windll.LoadLibrary("labjackud")
            staticLib.Close()
    CloseDevice = staticmethod(CloseDevice)

    #Linux and Mac only usb and ethernet write function
    #TODO Make for windows
    #TODO Make call eGetRaw
    def Write(Handle, Buffer, numBytes):
        """Writes a given buffer to the given LabJack device.

        USB for Linux, and Mac
        Ethernet for any python platform
        
        Sample Usage issuing a reset command to a U3 device:

        >>> sendBuff = [0] * 4
        >>> sendBuff[0] = 0x9B
        >>> sendBuff[1] = 0x99
        >>> sendBuff[2] = 0x02
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.Write(u3Handle, sendBuff, 4)
        >>> LabJackPython.Read(u3Handle, False, 4)
        (4, [-103, -103, 0, 0])

        
        @type  Handle: number
        @param Handle: Handle of the device to be closed.
        @type  Buffer: List
        @param Buffer: Buffer to be sent.  Data in the Buffer should be in hex format.
        @type  numBytes: number
        @param numBytes: The number of bytes to write.  Can be less than len(Buffer).
                
        @rtype: None
        @return: The function returns nothing.
        
        @raise LabJackException:
            - An exception is raised if the number of bytes written is less than 
            the number of bytes which were supposed to be written.
        """
        opSys = os.name
        
        if(isinstance(Handle, _UE9TCPHandle)):
            packFormat = "B" * len(Buffer)
            tempString = struct.pack(packFormat, *Buffer)
            Handle.socketA.send(tempString)
        else:
            if(opSys == 'posix'):
                staticLib = None
                handlePointer = ctypes.c_void_p(Handle)
                try:
                    staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.so")
                except:
                    try:
                        staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.dylib")
                    except:
                        raise LabJackException(0, "Write Buffer function could not load library")
                newA = (ctypes.c_byte*numBytes)(0) 
                for i in range(0, numBytes, 1):
                    newA[i] = ctypes.c_byte(Buffer[i])
                writeBytes = staticLib.LJUSB_BulkWrite(handlePointer, 1, ctypes.byref(newA), numBytes)
                if(writeBytes != numBytes):
                    raise LabJackException(0, "Could only write " + str(writeBytes) + " of " + str(numBytes) + " bytes")
            else:
                raise LabJackException(0, "Function only supported for Mac and Linux")
    Write = staticmethod(Write)

    #TODO Make for windows
    #TODO Make raise error
    #Linux and Mac only usb and ethernet read function
    def Read(Handle, Stream, numBytes):
        """Reads the current buffer from the given LabJackDevice.

        USB for Linux, and Mac
        Ethernet for any python platform
        
        The stream parameter should be true if the data to be read will come from the 
        devices stream buffer.  For all other data requests, the stream parameter 
        should be false.
        
        Sample Usage issuing a reset command to a U3 device:
        
        >>> sendBuff = [0] * 4
        >>> sendBuff[0] = 0x9B
        >>> sendBuff[1] = 0x99
        >>> sendBuff[2] = 0x02
        >>> u3Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "0", 1)
        >>> LabJackPython.Write(u3Handle, sendBuff, 4)
        >>> LabJackPython.Read(u3Handle, False, 4)
        (4, [-103, -103, 0, 0])

        @type  Handle: number
        @param Handle: Handle of the device to be closed.
        @type  Stream: boolean
        @param Stream: If the buffer to read is the Stream buffer or not.
        @type  numBytes: number
        @param numBytes: The number of bytes to read.  Can be less than len(Buffer).
                
        @rtype: Tuple
        @return: The tuple(readBytes, returnBuffer)
            - readBytes: The number of bytes read.
            - returnBuffer: The buffer which was read.
        
        @raise LabJackException:
        """
        opSys = os.name
        readBytes = 0
        returnBuffer = [[]] * numBytes
        
        
        if(isinstance(Handle, _UE9TCPHandle)):
            if(Stream):
                rcvString = Handle.socketB.recv(numBytes)
            else:
                rcvString = Handle.socketA.recv(numBytes)
            readBytes = len(rcvString)
            packFormat = "B" * readBytes
            rcvDataBuff = struct.unpack(packFormat, rcvString)
            
            for i in range(0, readBytes):
                returnBuffer[i] = rcvDataBuff[i] & 0xff
        else:
            if(opSys == 'posix'):
                staticLib = None
                handlePointer = ctypes.c_void_p(Handle)
                try:
                    staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.so")
                except:
                    try:
                        staticLib = ctypes.cdll.LoadLibrary("liblabjackusb.dylib")
                    except:
                        raise LabJackException("Write Buffer function could not load library")
                newA = (ctypes.c_byte*numBytes)()
                
                if(Stream):
                    readBytes = staticLib.LJUSB_BulkRead(handlePointer, 4, ctypes.byref(newA), numBytes)
                else:
                    readBytes = staticLib.LJUSB_BulkRead(handlePointer, 2, ctypes.byref(newA), numBytes)
                
                for i in range(0, numBytes):
                    returnBuffer[i] = newA[i] & 0xff

                return readBytes, returnBuffer
            else:
                raise LabJackException(0, "Function only supported for Mac and Linux")
    Read = staticmethod(Read)


    #Windows, Linux and Mac
    def DriverPresent():
        """Test to see if the operating systems driver is present.

        For Windows, Linux and Mac

        Sample Usage:

        >>> LabJackPython.DriverPresent()
        True
                
        @rtype: Boolean
        @return: The functions returns true or false.
        """     
        try:
            ctypes.windll.LoadLibrary("labjackud")
            return True
        except:
            try:
                ctypes.cdll.LoadLibrary("liblabjackusb.so")
                return True
            except:
                try:
                    ctypes.cdll.LoadLibrary("liblabjackusb.dylib")
                    return True
                except:
                    return False
                return False
            return False
        
    DriverPresent = staticmethod(DriverPresent)

    #Windows only
    def LJHash(hashStr, size):
        """An approximation of the md5 hashing algorithms.  

        For Windows
        
        An approximation of the md5 hashing algorithm.  Used 
        for authorizations on UE9 version 1.73 and higher and u3 
        version 1.35 and higher.

        @type  hashStr: String
        @param hashStr: String to be hashed.
        @type  size: number
        @param size: Amount of bytes to hash from the hashStr
                
        @rtype: String
        @return: The hashed string.
        """  
        
        print "Hash String:" + str(hashStr)
        
        outBuff = (ctypes.c_char * 16)()
        retBuff = ''
        
        staticLib = ctypes.windll.LoadLibrary("labjackud")
        
        ec = staticLib.LJHash(ctypes.cast(hashStr, ctypes.POINTER(ctypes.c_char)),
                              size, 
                              ctypes.cast(outBuff, ctypes.POINTER(ctypes.c_char)), 
                              0)
        if ec != 0: raise LabJackException(ec)

        for i in range(16):
            retBuff += outBuff[i]
            
        return retBuff
    LJHash = staticmethod(LJHash)


    #device types
    LJ_dtUE9 = 9
    """Device type for the UE9"""
    
    LJ_dtU3 = 3
    """Device type for the U3"""

    # connection types:
    LJ_ctUSB = 1 # UE9 + U3
    """Connection type for the UE9 and U3"""
    LJ_ctETHERNET = 2 # UE9 only
    """Connection type for the UE9"""

    LJ_ctUSB_RAW = 101 # UE9 + U3
    """Connection type for the UE9 and U3

    Raw connection types are used to open a device but not communicate with it
    should only be used if the normal connection types fail and for testing.
    If a device is opened with the raw connection types, only LJ_ioRAW_OUT
    and LJ_ioRAW_IN io types should be used
    """
    
    LJ_ctETHERNET_RAW = 102 # UE9 only
    """Connection type for the UE9

    Raw connection types are used to open a device but not communicate with it
    should only be used if the normal connection types fail and for testing.
    If a device is opened with the raw connection types, only LJ_ioRAW_OUT
    and LJ_ioRAW_IN io types should be used
    """
    

    # io types:
    LJ_ioGET_AIN = 10 # UE9 + U3.  This is single ended version.
    """IO type for the UE9 and U3
    
    This is the single ended version
    """  

    LJ_ioGET_AIN_DIFF = 15 # U3 only.  Put second channel in x1.  If 32 is passed as x1, Vref will be added to the result. 
    """IO type for the U3
    
    Put second channel in x1.  If 32 is passed as x1, Vref will be added to the result. 
    """

    LJ_ioPUT_AIN_RANGE = 2000 # UE9
    """IO type for the UE9"""
    
    LJ_ioGET_AIN_RANGE = 2001 # UE9
    """IO type for the UE9"""
    
    # sets or reads the analog or digital mode of the FIO and EIO pins.     FIO is Channel 0-7, EIO 8-15
    LJ_ioPUT_ANALOG_ENABLE_BIT = 2013 # U3 
    """IO type for the U3
    
    Sets or reads the analog or digital mode of the FIO and EIO pins.     FIO is Channel 0-7, EIO 8-15
    """
    
    LJ_ioGET_ANALOG_ENABLE_BIT = 2014 # U3 
    """IO type for the U3
    
    Sets or reads the analog or digital mode of the FIO and EIO pins.     FIO is Channel 0-7, EIO 8-15
    """
    
    
    # sets or reads the analog or digital mode of the FIO and EIO pins. Channel is starting 
    # bit #, x1 is number of bits to read. The pins are set by passing a bitmask as a double
    # for the value.  The first bit of the int that the double represents will be the setting 
    # for the pin number sent into the channel variable. 
    LJ_ioPUT_ANALOG_ENABLE_PORT = 2015 # U3 
    """ IO type for the U3
    
    sets or reads the analog or digital mode of the FIO and EIO pins. Channel is starting 
    bit #, x1 is number of bits to read. The pins are set by passing a bitmask as a double
    for the value.  The first bit of the int that the double represents will be the setting 
    for the pin number sent into the channel variable.
    """
    
    LJ_ioGET_ANALOG_ENABLE_PORT = 2016 # U3
    """ IO type for the U3
    
    sets or reads the analog or digital mode of the FIO and EIO pins. Channel is starting 
    bit #, x1 is number of bits to read. The pins are set by passing a bitmask as a double
    for the value.  The first bit of the int that the double represents will be the setting 
    for the pin number sent into the channel variable.
    """
    

    LJ_ioPUT_DAC = 20 # UE9 + U3
    """IO type for the U3 and UE9"""
    LJ_ioPUT_DAC_ENABLE = 2002 # UE9 + U3 (U3 on Channel 1 only)
    """IO type for the U3 and UE9
    
    U3 on channel 1 only.
    """
    LJ_ioGET_DAC_ENABLE = 2003 # UE9 + U3 (U3 on Channel 1 only)
    """IO type for the U3 and UE9
    
    U3 on channel 1 only.
    """

    LJ_ioGET_DIGITAL_BIT = 30 # UE9 + U3  # changes direction of bit to input as well
    LJ_ioGET_DIGITAL_BIT_DIR = 31 # U3
    LJ_ioGET_DIGITAL_BIT_STATE = 32 # does not change direction of bit, allowing readback of output

    # channel is starting bit #, x1 is number of bits to read 
    LJ_ioGET_DIGITAL_PORT = 35 # UE9 + U3  # changes direction of bits to input as well
    LJ_ioGET_DIGITAL_PORT_DIR = 36 # U3
    LJ_ioGET_DIGITAL_PORT_STATE = 37 # U3 does not change direction of bits, allowing readback of output

    # digital put commands will set the specified digital line(s) to output
    LJ_ioPUT_DIGITAL_BIT = 40 # UE9 + U3
    # channel is starting bit #, value is output value, x1 is bits to write
    LJ_ioPUT_DIGITAL_PORT = 45 # UE9 + U3

    # Used to create a pause between two events in a U3 low-level feedback
    # command.    For example, to create a 100 ms positive pulse on FIO0, add a
    # request to set FIO0 high, add a request for a wait of 100000, add a
    # request to set FIO0 low, then Go.     Channel is ignored.  Value is
    # microseconds to wait and should range from 0 to 8388480.    The actual
    # resolution of the wait is 128 microseconds.
    LJ_ioPUT_WAIT = 70 # U3

    # counter.    Input only.
    LJ_ioGET_COUNTER = 50 # UE9 + U3

    LJ_ioPUT_COUNTER_ENABLE = 2008 # UE9 + U3
    LJ_ioGET_COUNTER_ENABLE = 2009 # UE9 + U3


    # this will cause the designated counter to reset.    If you want to reset the counter with
    # every read, you have to use this command every time.
    LJ_ioPUT_COUNTER_RESET = 2012  # UE9 + U3 


    # on UE9: timer only used for input. Output Timers don't use these.     Only Channel used.
    # on U3: Channel used (0 or 1).     
    LJ_ioGET_TIMER = 60 # UE9 + U3

    LJ_ioPUT_TIMER_VALUE = 2006 # UE9 + U3.     Value gets new value
    LJ_ioPUT_TIMER_MODE = 2004 # UE9 + U3.    On both Value gets new mode.  
    LJ_ioGET_TIMER_MODE = 2005 # UE9

    # IOTypes for use with SHT sensor.    For LJ_ioSHT_GET_READING, a channel of LJ_chSHT_TEMP (5000) will 
    # read temperature, and LJ_chSHT_RH (5001) will read humidity.    
    # The LJ_ioSHT_DATA_CHANNEL and LJ_ioSHT_SCK_CHANNEL iotypes use the passed channel 
    # to set the appropriate channel for the data and SCK lines for the SHT sensor. 
    # Default digital channels are FIO0 for the data channel and FIO1 for the clock channel. 
    LJ_ioSHT_GET_READING = 500 # UE9 + U3.
    LJ_ioSHT_DATA_CHANNEL = 501 # UE9 + U3. Default is FIO0
    LJ_ioSHT_CLOCK_CHANNEL = 502 # UE9 + U3. Default is FIO1

    # Uses settings from LJ_chSPI special channels (set with LJ_ioPUT_CONFIG) to communcaite with
    # something using an SPI interface.     The value parameter is the number of bytes to transfer
    # and x1 is the address of the buffer.    The data from the buffer will be sent, then overwritten
    # with the data read.  The channel parameter is ignored. 
    LJ_ioSPI_COMMUNICATION = 503 # UE9

    # Set's the U3 to it's original configuration.    This means sending the following
    # to the ConfigIO and TimerClockConfig low level functions
    #
    # ConfigIO
    # Byte #
    # 6          WriteMask          15      Write all parameters.
    # 8          TimerCounterConfig      0          No timers/counters.  Offset=0.
    # 9          DAC1Enable      0          DAC1 disabled.
    # 10      FIOAnalog          0          FIO all digital.
    # 11      EIOAnalog          0          EIO all digital.
    # 
    # 
    # TimerClockConfig
    # Byte #
    # 8          TimerClockConfig          130      Set clock to 24 MHz.
    # 9          TimerClockDivisor          0          Divisor = 0.

    # 
    LJ_ioPIN_CONFIGURATION_RESET = 2017 # U3

    # the raw in/out are unusual, channel # corresponds to the particular comm port, which 
    # depends on the device.  For example, on the UE9, 0 is main comm port, and 1 is the streaming comm.
    # Make sure and pass a porter to a char buffer in x1, and the number of bytes desired in value.     A call 
    # to GetResult will return the number of bytes actually read/written.  The max you can send out in one call
    # is 512 bytes to the UE9 and 16384 bytes to the U3.
    LJ_ioRAW_OUT = 100 # UE9 + U3
    LJ_ioRAW_IN = 101 # UE9 + U3
    # sets the default power up settings based on the current settings of the device AS THIS DLL KNOWS.     This last part
    # basically means that you should set all parameters directly through this driver before calling this.    This writes 
    # to flash which has a limited lifetime, so do not do this too often.  Rated endurance is 20,000 writes.
    LJ_ioSET_DEFAULTS = 103 # U3

    # requests to create the list of channels to stream.  Usually you will use the CLEAR_STREAM_CHANNELS request first, which
    # will clear any existing channels, then use ADD_STREAM_CHANNEL multiple times to add your desired channels.  Some devices will 
    # use value, x1 for other parameters such as gain.    Note that you can do CLEAR, and then all your ADDs in a single Go() as long
    # as you add the requests in order.
    LJ_ioADD_STREAM_CHANNEL = 200
    LJ_ioCLEAR_STREAM_CHANNELS = 201
    LJ_ioSTART_STREAM = 202
    LJ_ioSTOP_STREAM = 203
     
    LJ_ioADD_STREAM_CHANNEL_DIFF = 206

    # Get stream data has several options.    If you just want to get a single channel's data (if streaming multiple channels), you 
    # can pass in the desired channel #, then the number of data points desired in Value, and a pointer to an array to put the 
    # data into as X1.    This array needs to be an array of doubles. Therefore, the array needs to be 8 * number of 
    # requested data points in byte length. What is returned depends on the StreamWaitMode.     If None, this function will only return 
    # data available at the time of the call.  You therefore must call GetResult() for this function to retrieve the actually number 
    # of points retreived.    If Pump or Sleep, it will return only when the appropriate number of points have been read or no 
    # new points arrive within 100ms.  Since there is this timeout, you still need to use GetResult() to determine if the timeout 
    # occured.    If AllOrNone, you again need to check GetResult.  

    # You can also retreive the entire scan by passing LJ_chALL_CHANNELS.  In this case, the Value determines the number of SCANS 
    # returned, and therefore, the array must be 8 * number of scans requested * number of channels in each scan.  Likewise
    # GetResult() will return the number of scans, not the number of data points returned.

    # Note: data is stored interleaved across all streaming channels.  In other words, if you are streaming two channels, 0 and 1, 
    # and you request LJ_chALL_CHANNELS, you will get, Channel0, Channel1, Channel0, Channel1, etc.     Once you have requested the 
    # data, any data returned is removed from the internal buffer, and the next request will give new data.

    # Note: if reading the data channel by channel and not using LJ_chALL_CHANNELS, the data is not removed from the internal buffer
    # until the data from the last channel in the scan is requested.  This means that if you are streaming three channels, 0, 1 and 2,
    # and you request data from channel 0, then channel 1, then channel 0 again, the request for channel 0 the second time will 
    # return the exact same amount of data.     Also note, that the amount of data that will be returned for each channel request will be
    # the same until you've read the last channel in the scan, at which point your next block may be a different size.

    # Note: although more convenient, requesting individual channels is slightly slower then using LJ_chALL_CHANNELS.  Since you 
    # are probably going to have to split the data out anyway, we have saved you the trouble with this option.    

    # Note: if you are only scanning one channel, the Channel parameter is ignored.

    LJ_ioGET_STREAM_DATA = 204
            
    # U3 only:

    # Channel = 0 buzz for a count, Channel = 1 buzz continuous
    # Value is the Period
    # X1 is the toggle count when channel = 0
    LJ_ioBUZZER = 300 # U3 

    # config iotypes:
    LJ_ioPUT_CONFIG = 1000 # UE9 + U3
    LJ_ioGET_CONFIG = 1001 # UE9 + U3


    # channel numbers used for CONFIG types:
    # UE9 + U3
    LJ_chLOCALID = 0 # UE9 + U3
    LJ_chHARDWARE_VERSION = 10 # UE9 + U3 (Read Only)
    LJ_chSERIAL_NUMBER = 12 # UE9 + U3 (Read Only)
    LJ_chFIRMWARE_VERSION = 11 # UE9 + U3 (Read Only)
    LJ_chBOOTLOADER_VERSION = 15 # UE9 + U3 (Read Only)

    # UE9 specific:
    LJ_chCOMM_POWER_LEVEL = 1 #UE9
    LJ_chIP_ADDRESS = 2 #UE9
    LJ_chGATEWAY = 3 #UE9
    LJ_chSUBNET = 4 #UE9
    LJ_chPORTA = 5 #UE9
    LJ_chPORTB = 6 #UE9
    LJ_chDHCP = 7 #UE9
    LJ_chPRODUCTID = 8 #UE9
    LJ_chMACADDRESS = 9 #UE9
    LJ_chCOMM_FIRMWARE_VERSION = 11     
    LJ_chCONTROL_POWER_LEVEL = 13 #UE9 
    LJ_chCONTROL_FIRMWARE_VERSION = 14 #UE9 (Read Only)
    LJ_chCONTROL_BOOTLOADER_VERSION = 15 #UE9 (Read Only)
    LJ_chCONTROL_RESET_SOURCE = 16 #UE9 (Read Only)
    LJ_chUE9_PRO = 19 # UE9 (Read Only)

    # U3 only:
    # sets the state of the LED 
    LJ_chLED_STATE = 17 # U3   value = LED state
    LJ_chSDA_SCL = 18 # U3     enable / disable SDA/SCL as digital I/O


    # Used to access calibration and user data.     The address of an array is passed in as x1.
    # For the UE9, a 1024-element buffer of bytes is passed for user data and a 128-element
    # buffer of doubles is passed for cal constants.
    # For the U3, a 256-element buffer of bytes is passed for user data and a 12-element
    # buffer of doubles is passed for cal constants.
    # The layout of cal ants are defined in the users guide for each device.
    # When the LJ_chCAL_CONSTANTS special channel is used with PUT_CONFIG, a
    # special value (0x4C6C) must be passed in to the Value parameter. This makes it
    # more difficult to accidently erase the cal constants.     In all other cases the Value
    # parameter is ignored.
    LJ_chCAL_CONSTANTS = 400 # UE9 + U3
    LJ_chUSER_MEM = 402 # UE9 + U3

    # Used to write and read the USB descriptor strings.  This is generally for OEMs
    # who wish to change the strings.
    # Pass the address of an array in x1.  Value parameter is ignored.
    # The array should be 128 elements of bytes.  The first 64 bytes are for the
    # iManufacturer string, and the 2nd 64 bytes are for the iProduct string.
    # The first byte of each 64 byte block (bytes 0 and 64) contains the number
    # of bytes in the string.  The second byte (bytes 1 and 65) is the USB spec
    # value for a string descriptor (0x03).     Bytes 2-63 and 66-127 contain unicode
    # encoded strings (up to 31 characters each).
    LJ_chUSB_STRINGS = 404 # U3


    # timer/counter related
    LJ_chNUMBER_TIMERS_ENABLED = 1000 # UE9 + U3
    LJ_chTIMER_CLOCK_BASE = 1001 # UE9 + U3
    LJ_chTIMER_CLOCK_DIVISOR = 1002 # UE9 + U3
    LJ_chTIMER_COUNTER_PIN_OFFSET = 1003 # U3

    # AIn related
    LJ_chAIN_RESOLUTION = 2000 # ue9 + u3
    LJ_chAIN_SETTLING_TIME = 2001 # ue9 + u3
    LJ_chAIN_BINARY = 2002 # ue9 + u3

    # DAC related
    LJ_chDAC_BINARY = 3000 # ue9 + u3

    # SHT related
    LJ_chSHT_TEMP = 5000 # ue9 + u3
    LJ_chSHT_RH = 5001 # ue9 + u3

    # SPI related
    LJ_chSPI_AUTO_CS = 5100 # UE9
    LJ_chSPI_DISABLE_DIR_CONFIG = 5101 # UE9
    LJ_chSPI_MODE = 5102 # UE9
    LJ_chSPI_CLOCK_FACTOR = 5103 # UE9
    LJ_chSPI_MOSI_PINNUM = 5104 # UE9
    LJ_chSPI_MISO_PINNUM = 5105 # UE9
    LJ_chSPI_CLK_PINNUM = 5106 # UE9
    LJ_chSPI_CS_PINNUM = 5107 # UE9

    # stream related.  Note, Putting to any of these values will stop any running streams.
    LJ_chSTREAM_SCAN_FREQUENCY = 4000
    LJ_chSTREAM_BUFFER_SIZE = 4001
    LJ_chSTREAM_CLOCK_OUTPUT = 4002
    LJ_chSTREAM_EXTERNAL_TRIGGER = 4003
    LJ_chSTREAM_WAIT_MODE = 4004
    # readonly stream related
    LJ_chSTREAM_BACKLOG_COMM = 4105
    LJ_chSTREAM_BACKLOG_CONTROL = 4106
    LJ_chSTREAM_BACKLOG_UD = 4107
    LJ_chSTREAM_SAMPLES_PER_PACKET = 4108


    # special channel #'s
    LJ_chALL_CHANNELS = -1
    LJ_INVALID_CONSTANT = -999


    #Thermocouple Type constants.
    LJ_ttB = 6001
    """Type B thermocouple constant"""
    LJ_ttE = 6002
    """Type E thermocouple constant"""
    LJ_ttJ = 6003
    """Type J thermocouple constant"""
    LJ_ttK = 6004
    """Type K thermocouple constant"""
    LJ_ttN = 6005
    """Type N thermocouple constant"""
    LJ_ttR = 6006
    """Type R thermocouple constant"""
    LJ_ttS = 6007
    """Type S thermocouple constant"""
    LJ_ttT = 6008
    """Type T thermocouple constant"""


    # other constants:
    # ranges (not all are supported by all devices):
    LJ_rgBIP20V = 1     # -20V to +20V
    LJ_rgBIP10V = 2     # -10V to +10V
    LJ_rgBIP5V = 3     # -5V to +5V
    LJ_rgBIP4V = 4     # -4V to +4V
    LJ_rgBIP2P5V = 5 # -2.5V to +2.5V
    LJ_rgBIP2V = 6     # -2V to +2V
    LJ_rgBIP1P25V = 7# -1.25V to +1.25V
    LJ_rgBIP1V = 8     # -1V to +1V
    LJ_rgBIPP625V = 9# -0.625V to +0.625V

    LJ_rgUNI20V = 101  # 0V to +20V
    LJ_rgUNI10V = 102  # 0V to +10V
    LJ_rgUNI5V = 103   # 0V to +5V
    LJ_rgUNI4V = 104   # 0V to +4V
    LJ_rgUNI2P5V = 105 # 0V to +2.5V
    LJ_rgUNI2V = 106   # 0V to +2V
    LJ_rgUNI1P25V = 107# 0V to +1.25V
    LJ_rgUNI1V = 108   # 0V to +1V
    LJ_rgUNIP625V = 109# 0V to +0.625V
    LJ_rgUNIP500V = 110 # 0V to +0.500V
    LJ_rgUNIP3125V = 111 # 0V to +0.3125V

    # timer modes (UE9 only):
    LJ_tmPWM16 = 0 # 16 bit PWM
    LJ_tmPWM8 = 1 # 8 bit PWM
    LJ_tmRISINGEDGES32 = 2 # 32-bit rising to rising edge measurement
    LJ_tmFALLINGEDGES32 = 3 # 32-bit falling to falling edge measurement
    LJ_tmDUTYCYCLE = 4 # duty cycle measurement
    LJ_tmFIRMCOUNTER = 5 # firmware based rising edge counter
    LJ_tmFIRMCOUNTERDEBOUNCE = 6 # firmware counter with debounce
    LJ_tmFREQOUT = 7 # frequency output
    LJ_tmQUAD = 8 # Quadrature
    LJ_tmTIMERSTOP = 9 # stops another timer after n pulses
    LJ_tmSYSTIMERLOW = 10 # read lower 32-bits of system timer
    LJ_tmSYSTIMERHIGH = 11 # read upper 32-bits of system timer
    LJ_tmRISINGEDGES16 = 12 # 16-bit rising to rising edge measurement
    LJ_tmFALLINGEDGES16 = 13 # 16-bit falling to falling edge measurement

    # timer clocks:
    LJ_tc750KHZ = 0      # UE9: 750 khz 
    LJ_tcSYS = 1      # UE9: system clock

    LJ_tc2MHZ = 10       # U3: Hardware Version 1.20 or lower
    LJ_tc6MHZ = 11       # U3: Hardware Version 1.20 or lower
    LJ_tc24MHZ = 12        # U3: Hardware Version 1.20 or lower
    LJ_tc500KHZ_DIV = 13# U3: Hardware Version 1.20 or lower
    LJ_tc2MHZ_DIV = 14    # U3: Hardware Version 1.20 or lower
    LJ_tc6MHZ_DIV = 15    # U3: Hardware Version 1.20 or lower
    LJ_tc24MHZ_DIV = 16 # U3: Hardware Version 1.20 or lower

    # stream wait modes
    LJ_swNONE = 1  # no wait, return whatever is available
    LJ_swALL_OR_NONE = 2 # no wait, but if all points requested aren't available, return none.
    LJ_swPUMP = 11    # wait and pump the message pump.  Prefered when called from primary thread (if you don't know
                               # if you are in the primary thread of your app then you probably are.  Do not use in worker
                               # secondary threads (i.e. ones without a message pump).
    LJ_swSLEEP = 12 # wait by sleeping (don't do this in the primary thread of your app, or it will temporarily 
                               # hang)    This is usually used in worker secondary threads.


    # BETA CONSTANTS
    # Please note that specific usage of these constants and their values might change

    # SWDT related 
    LJ_chSWDT_RESET_COMM = 5200 # UE9 - Reset Comm on watchdog reset
    LJ_chSWDT_RESET_CONTROL = 5201 # UE9 - Reset Control on watchdog trigger
    LJ_chSWDT_UDPATE_DIO0 = 5202 # UE9 - Update DIO0 settings after reset
    LJ_chSWDT_UPDATE_DIO1 = 5203 # UE9 - Update DIO1 settings after reset
    LJ_chSWDT_DIO0 = 5204 # UE9 - DIO0 channel and state (value) to be set after reset
    LJ_chSWDT_DIO1 = 5205 # UE9 - DIO1 channel and state (value) to be set after reset
    LJ_chSWDT_UPDATE_DAC0 = 5206 # UE9 - Update DAC1 settings after reset
    LJ_chSWDT_UPDATE_DAC1 = 5207 # UE9 - Update DAC1 settings after reset
    LJ_chSWDT_DAC0 = 5208 # UE9 - voltage to set DAC0 at on watchdog reset
    LJ_chSWDT_DAC1 = 5209 # UE9 - voltage to set DAC1 at on watchdog reset
    LJ_chSWDT_DACS_ENABLE = 5210 # UE9 - Enable DACs on watchdog reset
    LJ_chSWDT_ENABLE = 5211 # UE9 - used with LJ_ioSWDT_CONFIG to enable watchdog.    Value paramter is number of seconds to trigger
    LJ_chSWDT_DISABLE = 5212 # UE9 - used with LJ_ioSWDT_CONFIG to enable watchdog.

    LJ_ioSWDT_CONFIG = 504 # UE9 - Use LJ_chSWDT_ENABLE or LJ_chSWDT_DISABLE

    LJ_tc4MHZ = 20       # U3: Hardware Version 1.21 or higher
    LJ_tc12MHZ = 21        # U3: Hardware Version 1.21 or higher
    LJ_tc48MHZ = 22        # U3: Hardware Version 1.21 or higher
    LJ_tc1000KHZ_DIV = 23# U3: Hardware Version 1.21 or higher
    LJ_tc4MHZ_DIV = 24    # U3: Hardware Version 1.21 or higher
    LJ_tc12MHZ_DIV = 25     # U3: Hardware Version 1.21 or higher
    LJ_tc48MHZ_DIV = 26 # U3: Hardware Version 1.21 or higher

    # END BETA CONSTANTS


    # error codes:    These will always be in the range of -1000 to 3999 for labView compatibility (+6000)
    LJE_NOERROR = 0
     
    LJE_INVALID_CHANNEL_NUMBER = 2 # occurs when a channel that doesn't exist is specified (i.e. DAC #2 on a UE9), or data from streaming is requested on a channel that isn't streaming
    LJE_INVALID_RAW_INOUT_PARAMETER = 3
    LJE_UNABLE_TO_START_STREAM = 4
    LJE_UNABLE_TO_STOP_STREAM = 5
    LJE_NOTHING_TO_STREAM = 6
    LJE_UNABLE_TO_CONFIG_STREAM = 7
    LJE_BUFFER_OVERRUN = 8 # occurs when stream buffer overruns (this is the driver buffer not the hardware buffer).  Stream is stopped.
    LJE_STREAM_NOT_RUNNING = 9
    LJE_INVALID_PARAMETER = 10
    LJE_INVALID_STREAM_FREQUENCY = 11 
    LJE_INVALID_AIN_RANGE = 12
    LJE_STREAM_CHECKSUM_ERROR = 13 # occurs when a stream packet fails checksum.  Stream is stopped
    LJE_STREAM_COMMAND_ERROR = 14 # occurs when a stream packet has invalid command values.     Stream is stopped.
    LJE_STREAM_ORDER_ERROR = 15 # occurs when a stream packet is received out of order (typically one is missing).    Stream is stopped.
    LJE_AD_PIN_CONFIGURATION_ERROR = 16 # occurs when an analog or digital request was made on a pin that isn't configured for that type of request
    LJE_REQUEST_NOT_PROCESSED = 17 # When a LJE_AD_PIN_CONFIGURATION_ERROR occurs, all other IO requests after the request that caused the error won't be processed. Those requests will return this error.


    # U3 Specific Errors
    LJE_SCRATCH_ERROR = 19
    """U3 error"""
    LJE_DATA_BUFFER_OVERFLOW = 20
    """U3 error"""
    LJE_ADC0_BUFFER_OVERFLOW = 21 
    """U3 error"""
    LJE_FUNCTION_INVALID = 22
    """U3 error"""
    LJE_SWDT_TIME_INVALID = 23
    """U3 error"""
    LJE_FLASH_ERROR = 24
    """U3 error"""
    LJE_STREAM_IS_ACTIVE = 25
    """U3 error"""
    LJE_STREAM_TABLE_INVALID = 26
    """U3 error"""
    LJE_STREAM_CONFIG_INVALID = 27
    """U3 error"""
    LJE_STREAM_BAD_TRIGGER_SOURCE = 28
    """U3 error"""
    LJE_STREAM_INVALID_TRIGGER = 30
    """U3 error"""
    LJE_STREAM_ADC0_BUFFER_OVERFLOW = 31
    """U3 error"""
    LJE_STREAM_SAMPLE_NUM_INVALID = 33
    """U3 error"""
    LJE_STREAM_BIPOLAR_GAIN_INVALID = 34
    """U3 error"""
    LJE_STREAM_SCAN_RATE_INVALID = 35
    """U3 error"""
    LJE_TIMER_INVALID_MODE = 36
    """U3 error"""
    LJE_TIMER_QUADRATURE_AB_ERROR = 37
    """U3 error"""
    LJE_TIMER_QUAD_PULSE_SEQUENCE = 38
    """U3 error"""
    LJE_TIMER_BAD_CLOCK_SOURCE = 39
    """U3 error"""
    LJE_TIMER_STREAM_ACTIVE = 40
    """U3 error"""
    LJE_TIMER_PWMSTOP_MODULE_ERROR = 41
    """U3 error"""
    LJE_TIMER_SEQUENCE_ERROR = 42
    """U3 error"""
    LJE_TIMER_SHARING_ERROR = 43
    """U3 error"""
    LJE_TIMER_LINE_SEQUENCE_ERROR = 44
    """U3 error"""
    LJE_EXT_OSC_NOT_STABLE = 45
    """U3 error"""
    LJE_INVALID_POWER_SETTING = 46
    """U3 error"""
    LJE_PLL_NOT_LOCKED = 47
    """U3 error"""
    LJE_INVALID_PIN = 48
    """U3 error"""
    LJE_IOTYPE_SYNCH_ERROR = 49
    """U3 error"""
    LJE_INVALID_OFFSET = 50
    """U3 error"""
    LJE_FEEDBACK_IOTYPE_NOT_VALID = 51
    """U3 error
    
    Has been described as mearly a flesh wound.
    """

    LJE_SHT_CRC = 52
    LJE_SHT_MEASREADY = 53
    LJE_SHT_ACK = 54
    LJE_SHT_SERIAL_RESET = 55
    LJE_SHT_COMMUNICATION = 56

    LJE_AIN_WHILE_STREAMING = 57

    LJE_STREAM_TIMEOUT = 58
    LJE_STREAM_CONTROL_BUFFER_OVERFLOW = 59
    LJE_STREAM_SCAN_OVERLAP = 60
    LJE_FIRMWARE_DOESNT_SUPPORT_IOTYPE = 61
    LJE_FIRMWARE_DOESNT_SUPPORT_CHANNEL = 62
    LJE_FIRMWARE_DOESNT_SUPPORT_VALUE = 63


    LJE_MIN_GROUP_ERROR = 1000 # all errors above this number will stop all requests, below this number are request level errors.

    LJE_UNKNOWN_ERROR = 1001 # occurs when an unknown error occurs that is caught, but still unknown.
    LJE_INVALID_DEVICE_TYPE = 1002 # occurs when devicetype is not a valid device type
    LJE_INVALID_HANDLE = 1003 # occurs when invalid handle used
    LJE_DEVICE_NOT_OPEN = 1004    # occurs when Open() fails and AppendRead called despite.
    LJE_NO_DATA_AVAILABLE = 1005 # this is cause when GetData() called without calling DoRead(), or when GetData() passed channel that wasn't read
    LJE_NO_MORE_DATA_AVAILABLE = 1006
    LJE_LABJACK_NOT_FOUND = 1007 # occurs when the labjack is not found at the given id or address.
    LJE_COMM_FAILURE = 1008 # occurs when unable to send or receive the correct # of bytes
    LJE_CHECKSUM_ERROR = 1009
    LJE_DEVICE_ALREADY_OPEN = 1010 
    LJE_COMM_TIMEOUT = 1011
    LJE_USB_DRIVER_NOT_FOUND = 1012
    LJE_INVALID_CONNECTION_TYPE = 1013
    LJE_INVALID_MODE = 1014


    # warning are negative
    LJE_DEVICE_NOT_CALIBRATED = -1 # defaults used instead
    LJE_UNABLE_TO_READ_CALDATA = -2 # defaults used instead


    # depreciated constants:
    LJ_ioANALOG_INPUT = 10  
    """Deprecated constant"""  
    LJ_ioANALOG_OUTPUT = 20 # UE9 + U3
    """Deprecated constant"""  
    LJ_ioDIGITAL_BIT_IN = 30 # UE9 + U3
    """Deprecated constant"""  
    LJ_ioDIGITAL_PORT_IN = 35 # UE9 + U3 
    """Deprecated constant"""  
    LJ_ioDIGITAL_BIT_OUT = 40 # UE9 + U3
    """Deprecated constant"""  
    LJ_ioDIGITAL_PORT_OUT = 45 # UE9 + U3
    """Deprecated constant"""  
    LJ_ioCOUNTER = 50 # UE9 + U3
    """Deprecated constant"""  
    LJ_ioTIMER = 60 # UE9 + U3
    """Deprecated constant"""  
    LJ_ioPUT_COUNTER_MODE = 2010 # UE9
    """Deprecated constant"""  
    LJ_ioGET_COUNTER_MODE = 2011 # UE9
    """Deprecated constant"""  
    LJ_ioGET_TIMER_VALUE = 2007 # UE9
    """Deprecated constant"""  
    LJ_ioCYCLE_PORT = 102  # UE9 
    """Deprecated constant"""  
    LJ_chTIMER_CLOCK_CONFIG = 1001 # UE9 + U3 
    """Deprecated constant"""  
    LJ_ioPUT_CAL_CONSTANTS = 400
    """Deprecated constant"""  
    LJ_ioGET_CAL_CONSTANTS = 401
    """Deprecated constant"""  
    LJ_ioPUT_USER_MEM = 402
    """Deprecated constant"""  
    LJ_ioGET_USER_MEM = 403
    """Deprecated constant"""  
    LJ_ioPUT_USB_STRINGS = 404
    """Deprecated constant"""  
    LJ_ioGET_USB_STRINGS = 405
    """Deprecated constant"""  

