"""
" WindowsDriverSample.py
" Author: LabJack Corporation
"
"
" This driver shows some of the basic functions 
" of the LabJackPython driver.
"""

#The LabJackPython.pyc file should be in the Python\Lib directory
from LabJackPython import LabJackPython

try:
    if __name__ == "__main__":
        
        #Open a UE9 over usb with the first found flag.
        ue9Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtUE9, LabJackPython.LJ_ctUSB, "0", 1)
        
        #Get Channel 0
        ain0 = LabJackPython.eGet(ue9Handle, LabJackPython.LJ_ioGET_AIN, 0, 0, 0)
        print "eGet AIN0:" + str(ain0)

        #Add request to get channel 0
        LabJackPython.AddRequest(ue9Handle,LabJackPython.LJ_ioGET_AIN, 0, 0.0, 0, 0.0)
        LabJackPython.Go()
        ain0 = LabJackPython.GetResult(ue9Handle, LabJackPython.LJ_ioGET_AIN, 0)
        print "addRequest AIN0:" + str(ain0)
        
except Exception, e: 
    print "Exception:" + str(e)
    
    