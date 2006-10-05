Simlink Software Development API for DOS, Version 2.04

UPDATED 30 Jan '98: EDF2ASC
UPDATED 27 Jan '98: EDFVIEW, EDFVIEWX

This file contains installation instructions for SIMLINK.
Please refer to the printed manual for instructions on use.

1) If you have a previous installation of SIMLINK, back it up, 
   copy it to a new directory, OSIMLINK, and completely remove 
   the old directory:

   xcopy \simlink\*.*  \osimlink\*.*  /s
   deltree \simlink

2) Create a new SIMLINK directory, and copy the SIMLINK.ZIP file into it:
   
   md \simlink
   cd \simlink
   copy a:simlink.zip

3) Unzip the files (if you don't have PKUNZIP on your PC, copy it first)
  
   pkunzip -d simlink.zip

4) If you have used older versions of SIMLINK, be sure to read 
   the section on converting old executables in the manual.


If you encounter problems during this installation or have further questions,
please contact SMI SensoMotoric Instruments for support:
phone Germany   +49-3328-39550
phone USA       1-888-SMIUSA1
email           eyelink_support@smi.de
