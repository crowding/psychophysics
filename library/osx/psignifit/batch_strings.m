% BATCH_STRINGS    explanation of the batch string format
% 
%   Batch strings are the format in which options must be specified for
%   the MEX files in the psychometric functions toolbox. See below for an
%   example that illustrates the format.
%     
%   Batch strings in MATLAB are horizontal string vectors, containing
%   newline characters, suitable for reading from and writing to ordinary
%   text files. The rules for construction of a batch string follow. If using
%   MATLAB 5, you do not need to worry about this because the function
%   BATCH will construct the string for you from ordinary MATLAB matrices and
%   variables.
% 
%   Batch strings are used rather than MATLAB structs in order to allow the
%   MEX files to be used with MATLAB 4, and also to retain compatibility with
%   the UNIX command-line and stand-alone versions of the software. Note that
%   most of the accompanying M-files, by contrast, are NOT compatible with
%   MATLAB 4. As a result, if MATLAB 5 is unavailable, batch strings will be
%   more conveniently read from text files, instead of being generated on the
%   command line.
%   
%   Variables are recorded in a batch string in key/value pairs. Keys must
%   be prefixed by the character #, and must be the first word of a line.
%   There should be no whitespace between the # and they key word, because
%   this causes the variable to be ignored: entries can be "commented out"
%   conveniently in this way.
%   
%   Values are separated from their keys by whitespace. There are two sorts
%   of values: strings, and lists of numbers.
%   
%   Strings variables within a batch string can contain any characters.
%   Quotes are not needed, and are undesirable in most cases because they
%   will be interpreted literally.
%   
%   Numbers may be expressed in a variety of formats, as illustrated in the
%   example below. Numbers in a list may be delimited by commas, semicolons
%   or whitespace. Brackets are not required, but a single pair encompassing
%   the whole list is permitted: {}, [] or ().
% 
%   See BATCH, BATCH2STRUCT and STRUCT2BATCH for a convenient
%   interface with MATLAB 5.
% 
%   Example of a batch string:
% 
%     #name          NJH
%     #eyes          2
%         #colour    brown
%         #glasses   true
%   
%     #favourite_food    #-browns
%     
%     #favourite_numbers
%       
%       [  -INF, 
%           0, 1, 3.1415927,
%         6.02e23;
%         EPS  65536, NAN
%         2/3                25]
%     
%     # oops
%            this field will not be read, because of
%            the whitespace between the # and the key word

% Part of the psignifit toolbox version 2.5.6 for MATLAB version 5 and up.
% Copyright (c) J.Hill 1999-2005.
% Please read the LICENSE and NO WARRANTY statement in psych_legal.m
% mailto:psignifit@bootstrap-software.org
% http://bootstrap-software.org/psignifit/
