function names = createfnames(spec,source,varargin)
%names=createfnames(spec,source [,ext] [,var1,var2,..])
%
%   SPEC    0, files from a search path specified in SOURCE
%           1, files specifed directly in file SOURCE in the Matlab path.
%   SOURCE  Either search path or file containing filenames. 
%   EXT     Gives the opportunity to add an extension to the
%           filenames. This could be useful if the same specification
%           file should be used for input and output files. The extension
%           will be added _before_ the file type extension ".mat".
%   VARn    These optional parameters specify to only choose infiles that
%           contain all of the specified variable names.( This is
%           currently not implemented.)
  
% extract the path 
if isunix
  t = '/';
else
  t = '\';
end
[mask,path] = strtok(fliplr([source ' ']),t);
path = fliplr(path);

if nargin >= 3
  ext = varargin{1};
else
  ext = '';
end

if nargin > 3
  disp('this is currently not implemented')
  return;
end

% get input file names
%---------------------
if spec
  % use a specification file.
  names = textread(source,'%s','commentstyle','matlab','delimiter','\n');
  names = names(~strcmp('',names));
else
  % use a path.
  names = dir(source);
  names = {names.name}';
  for n = 1:length(names)
    names{n} = [path names{n}];
  end
end

if ~isempty(ext)
  for n=1:length(names)
    names {n} = [names{n}(1:end-4) ext '.mat'];
  end
end



