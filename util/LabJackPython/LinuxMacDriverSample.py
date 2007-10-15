"""
" LinuxMacDriverSample.py
" Author: LabJack Corporation
"
"
" This driver shows a comm config call to the UE9.
"""

#The LabJackPython.pyc file should be in the Python\Lib directory
from LabJackPython import LabJackPython

try:
    if __name__ == "__main__":
        
        
        #Create a simple comm config packet to 
        #read all data from the UE9
        sendBuffer = [0] * 38
        
        sendBuffer[0] = 0x89
        sendBuffer[1] = 0x78
        sendBuffer[2] = 0x10
        sendBuffer[3] = 0x01 
        
        #Open a UE9 over usb with the first found flag.
        ue9Handle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtUE9, LabJackPython.LJ_ctUSB, "0", 1)
        
        #Write a command to get the version numbers from the UE9
        LabJackPython.Write(ue9Handle, sendBuffer, len(sendBuffer))
        
        numBytes, rcvBuffer = LabJackPython.Read(ue9Handle, False, 38)
        
        localID = int(rcvBuffer[8])
        ipAddress = str(int(rcvBuffer[13])) + "." + str(int(rcvBuffer[12])) + "." + str(int(rcvBuffer[11])) + "." + str(int(rcvBuffer[10]))
        gateway = str(int(rcvBuffer[17])) + "." + str(int(rcvBuffer[16])) + "." + str(int(rcvBuffer[15])) + "." + str(int(rcvBuffer[14]))
        subnet = str(int(rcvBuffer[21])) + "." + str(int(rcvBuffer[20])) + "." + str(int(rcvBuffer[19])) + "." + str(int(rcvBuffer[18]))
        dataPort = (int(rcvBuffer[23]) << 8) + int(rcvBuffer[22])
        streamPort = (int(rcvBuffer[25]) << 8) + int(rcvBuffer[24])
        dhcp = int(rcvBuffer[26])
        prodID = int(rcvBuffer[27])
        macAddr = (int(rcvBuffer[33]) << 40) + (int(rcvBuffer[32]) << 32) + (int(rcvBuffer[31]) << 24) + (int(rcvBuffer[30]) << 16) + (int(rcvBuffer[29]) << 8) + (int(rcvBuffer[28]))    
        hwVer = int(rcvBuffer[35]) + (float(rcvBuffer[34]) / 100.0)
        commFWVer = int(rcvBuffer[37]) + (float(rcvBuffer[36]) / 100.0)
        
        print "UE9 Information:"
        print "  LocalID:" + str(localID)
        print "  IP:" + str(ipAddress)
        print "  Gateway:" + str(gateway)
        print "  subnet:" + str(subnet)
        print "  dataPort:" + str(dataPort)
        print "  streamPort:" + str(streamPort)
        print "  dchp enabled:" + str(dhcp)
        print "  Product ID:" + str(prodID)
        print "  macAddr:" + str(macAddr)
        print "  hwVer:" + str(hwVer)
        print "  comm Firmware Ver:" + str(commFWVer)
        
except Exception, e: 
    print "Exception:" + str(e)