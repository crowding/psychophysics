This file contains installation instructions for EYELINK version 2.04.
Please refer to the printed "EyeLink System Documentation" manual for
instructions on use.

1) If you have a previous installation of EYELINK, make sure
   that its directory name (usually EYELINK.nnn, with "nnn" referring
   to your current version number) is different from \EYELINK.204

2) Create a new EYELINK directory, and copy the EYELINK.ZIP file from
   this installation disk into it:
   
   md \eyelink.204
   cd \eyelink.204
   copy a:eyelink.zip

3) Unzip the files (if you don't have PKUNZIP on your PC, copy it first)
  
   pkunzip -d eyelink.zip

4) If you replaced an old installation, copy back the old setup files
   that  match your installation.

   copy \eyelink.nnn\exe\physical.ini \eyelink.204\exe
   copy \eyelink.nnn\exe\buttons.ini  \eyelink.204\exe

5) If this is an update of a previous EyeLink version, open \AUTOEXEC.BAT
   with an editor and change all references to the old directory \EYELINK.nnn
   into \EYELINK.204.
   If this is a new installation, follow the instructions in the manual
   on modifying AUTOEXEC.BAT to complete the installation.

******************** IMPORTANT *********************

6) Check your \AUTOEXEC.BAT file for the following line:
   \eyelink.204\exe\elreset
   
   If this line is not yet present, please add it to the beginning of your
   \AUTOEXEC.BAT 


If you encounter problems during this installation or have further questions,
please contact SMI SensoMotoric Instruments for support:
phone Germany   +49-3328-39550
phone USA       1-888-SMIUSA1
email           eyelink_support@smi.de
