% This file can be executed simply by typing "filtbatch".
% It applies a simple algorithm on different images saved on disk.
% The results are saved to files.
%
% Make sure that "infiles.txt" contains the filenames of existing data
% files containing the variable 'img'.
% Sample images are created using create_img.m

echo on
% A number of images stored in files will be loaded and an avereging
% filter will be applied. 

% This is a file containing the filenames. Each of the files indicated
% therein should contain a 2D intensity matrix with the name 'img'.
infiles = 'infiles.txt'; 

% The filter to apply:
B = repmat(1/100,10,10);

w = pmfun; 
w.expr='img2=conv2(B,img);'; % what each slave should evaluate.
w.argin = {'img'};          % the input file should contain this variable
w.argout = {'img2'};         % the output will be saved with this name
w.datain = {'LOADFILE(1)'}; % Let slave instance load its data.
w.dataout= {'SAVEFILE(1)'}; % and then save the result.
w.comarg = {'B'};           % the filter is same for all images.
w.comdata = {'INPUT(1)'};   % and will be given as input to the dispatcher.

% create cell arrays containing the different filenames of the input
innames = createfnames(1,infiles);
% create cell arrays containing the different filenames of the output
outnames = createfnames(1,infiles,'_modified');

% create a pmblock structure describing the filenames in the pmfun: w.
w.blocks = pmblock('srcfile',innames,'dstfile',outnames);

% Now, dispatch the filtering of all images, use the virtual machine 0:
err = dispatch(w,0,{B});

echo off


