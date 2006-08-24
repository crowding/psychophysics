function initializer = SetupEyelinkExperiment(varargin)
%produces an initializer for use with REQUIRE.
%any arguments given will be curried to the initializer.
%
%sets up the screen display and the eyelink connection.
%combines getScreen with getEyelink.
%
%Use as follows:
%require(@setupEyelinkExperiment, @myExperiment)
%where 'myExperiment' is the function that runs your experiment.
%
%myExperiment will get a single struct argument with these fields:
%   (from getScreen)
%       screenNumber - the screen number of the display
%       window - the PTB window handle
%       rect - the screen rectangle coordinates
%       cal - the calibration being used
%       black
%       white 
%       gray - indexes into the colortable
%	(from getEyelink)
%       el - the eyelink info structure
%       edfname - the EDF file name
%       localname - full path to where the EDF file is downloaded locally
%       dummy - whether the eyelink was opened in dummy mode

initializer = currynamedargs(...
    joinResource(getScreen(), getEyelink()),...
    varargin{:})
