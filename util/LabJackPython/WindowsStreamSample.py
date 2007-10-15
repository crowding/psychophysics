"""
" WindowsStreamSample.py
" Author: LabJack Corporation
" Date: 01.09.2007
"
" A basic streaming program for use with the Windows Python drivers for the LabJack
" U3 and UE9.  With no modifications to the file, a UE9 device will stream channels
" AIN2 and AIN3 every 10ms.  Uncommenting the U3 section will enable the stream
" to work with a U3.
"""

#The LabJackPython.pyc file should be in the Python\Lib directory
from LabJackPython import LabJackPython
from LabJackPython import LabJackException
import msvcrt

try:
    if __name__ == "__main__":
        
        scanrate = 100
        done = False
        numReads = 0
        
        #Open a UE9 over usb with the first found flag.
        #Comment out if using a U3
        deviceHandle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtUE9, LabJackPython.LJ_ctUSB, "1", 1)
        
        #FOR U3 ONLY Uncomment if using a U3
        #Open the U3 Device
        #deviceHandle = LabJackPython.OpenLabJack(LabJackPython.LJ_dtU3, LabJackPython.LJ_ctUSB, "1", 1)
        #Set FIO 2 and 3 as Analog Inputs
        #LabJackPython.ePut(deviceHandle, LabJackPython.LJ_ioPUT_ANALOG_ENABLE_BIT, 3, 1, 0)
        #LabJackPython.ePut(deviceHandle, LabJackPython.LJ_ioPUT_ANALOG_ENABLE_BIT, 2, 1, 0)
        
        #Configure the Stream Mode:
        #Configure all analog inputs for 12-bit resolution
        LabJackPython.AddRequest(deviceHandle, LabJackPython.LJ_ioPUT_CONFIG, LabJackPython.LJ_chAIN_RESOLUTION, 12, 0, 0);
    
        #Configure the analog input range on channel 0 for bipolar +-5 volts.
        LabJackPython.AddRequest(deviceHandle, LabJackPython.LJ_ioPUT_AIN_RANGE, 0, LabJackPython.LJ_rgBIP5V, 0, 0);
        
        #Set the scanrate of the Stream mode.
        LabJackPython.AddRequest( deviceHandle, LabJackPython.LJ_ioPUT_CONFIG, LabJackPython.LJ_chSTREAM_SCAN_FREQUENCY, scanrate, 0, 0)

        #Give the UD driver a 5 second buffer (scanrate * 2channels * 5seconds
        LabJackPython.AddRequest(deviceHandle, LabJackPython.LJ_ioPUT_CONFIG, LabJackPython.LJ_chSTREAM_BUFFER_SIZE, scanrate * 2 * 5, 0, 0)

        #Configure reads to wanrieve the desired amount of data. 
        LabJackPython.AddRequest(deviceHandle, LabJackPython.LJ_ioPUT_CONFIG, LabJackPython.LJ_chSTREAM_WAIT_MODE, LabJackPython.LJ_swSLEEP, 0, 0)

        #Define the scan list as AIN2 then AIN3. 
        LabJackPython.AddRequest(deviceHandle, LabJackPython.LJ_ioCLEAR_STREAM_CHANNELS, 0, 0, 0, 0)
        LabJackPython.AddRequest(deviceHandle, LabJackPython.LJ_ioADD_STREAM_CHANNEL, 2, 0, 0, 0)
        LabJackPython.AddRequest(deviceHandle, LabJackPython.LJ_ioADD_STREAM_CHANNEL, 3, 0, 0, 0)

        #Apply the requests prior to starting streaming.
        LabJackPython.GoOne(deviceHandle)
        
        #Get all the Results until an exception is thrown
        try: 
            rIOType, rChannel, rValue, rxValue, rudValue = LabJackPython.GetFirstResult(deviceHandle)
            while (True):
                rIOType, rChannel, rValue, rxValue, rudValue = LabJackPython.GetNextResult(deviceHandle)
        except LabJackException, lje:
            print "Recieved Exception:" + str(lje)
        
        #Start the Stream
        actualScanRate = LabJackPython.eGet(deviceHandle, LabJackPython.LJ_ioSTART_STREAM, 0, 0, 0)
        
        #Since the actual scan rate is based on how the desired
        #scan rate divides into the LabJack's clock
        #the actual scan rate is returned in eGet's pValue parameter 
        #which is the return parameter of eGet.
        print "Scanrate " + str(scanrate) + " requested."
        print "Stream started running with " + str(actualScanRate) + " scanrate."
        
        #Read 10 Scans
        while not msvcrt.kbhit():            
            
            try:
                print "Iteration Number:" + str(numReads)
                numReads += 1
                #Must set the number of scans to read each iteration, as the read
                #returns the actual number read.
                numScans = 5;
                
                #Set the dataArray to hold the proper size of the data to be read 
                #which is numScans * numChannels
                dataArray = [9999.0] * 2 * numScans 
                
                #Read the data. Note that the array passed must be sized to hold 
                #enough SAMPLES, and the Value passed specifies the number of SCANS 
                #to read. 
                actualNumberRead, dataArray = LabJackPython.eGetRaw(deviceHandle, LabJackPython.LJ_ioGET_STREAM_DATA, LabJackPython.LJ_chALL_CHANNELS, numScans, dataArray) 
                print "anr:" + str(actualNumberRead)
                #When all channels are retrieved in a single read, 
                #is interleaved in a 1-dimensional array. The following lines
                #get the first sample from each channel. 
                print "First Scan: %.3f     %.3f" % (dataArray[0],dataArray[1]) 
                
                
                #Retrieve the current Comm backlog. The UD driver retrieves 
                #stream data from the UE9 in the background, but if the computer
                #is too slow for some reason the driver might not be able to read 
                #the data as fast as the UE9 is acquiring it, and thus there will 
                #be data left over in the UE9 buffer. 
                commBackLog = LabJackPython.eGet(deviceHandle, LabJackPython.LJ_ioGET_CONFIG, LabJackPython.LJ_chSTREAM_BACKLOG_COMM, 0, 0)
            
                print "Commbacklog:" + str(commBackLog)
            
                #Increment the read counter
                print "\n"
                #time.sleep(1)
            
            except Exception, e:
                print "Exception:" + str(e)
    
        
        #Stop the stream. 
        LabJackPython.ePut (deviceHandle, LabJackPython.LJ_ioSTOP_STREAM, 0, 0, 0)
        
except Exception, e: 
    print "Exception:" + str(e)
    