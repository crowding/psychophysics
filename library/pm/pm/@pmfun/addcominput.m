%ADDCOMINPUT Adds a common input definition to the pmfun
%   F = ADDCOMINPUT(F,NAME,DATA) Adds a variable with the name NAME to
%   the common input of the function definition F. DATA can be:
%     'INPUT' Meaning that the input will be provided by the user input
%             to the dispatcher.
%     'LOAD'  Meaning that a filename to load will be provided by the
%             user input to the dispatcher. Each Matlab instance will
%             load the variable with name NAME from this file before
%             starting the dispatch.
%     Arbitrary Matlab data - this avoids passing the data through the
%             input of the dispatcher, and leaves the function definition
%             less flexible.
%
%   F = ADDCOMINPUT(F,NAME,DATA,IND) Does the same as above but allows
%   the user to specify which dispatcher input that should be used. Note
%   that this may change when other data that accesses the dispatcher
%   input is added ('GETBLOC' in the specific input which will always get
%   its input from arguments before the common arguments). This may be
%   form may be useful when two variables are to be loaded from the same
%   file. 
%
%   Example:
%      f = pmfun;
%      f = addcominput(f,'ref_img','LOAD');
%      f = addcominput(f,'ref_param','LOAD',1); % from same file!
%      f = addcominput(f,'options',[1 2 3]) % always send this! 
%      f = addspecinput(f,'img1','GETBLOC') % now the LOAD inputs increase
%  
%   See also: DELCOMINPUT, ADDSPECINPUT, DELSPECINPUT, ADDOUTPUT, DELOUTPUT.

function f = addcominput(f,name,data,varargin)
  
f.comarg{end+1} = name;
direct = 0;
if ~ischar(data)
  direct = 1;
elseif ~any(strcmp(data,{'INPUT','LOAD'}))
  direct = 1;
end
if direct 
  f.comdata{end+1} = data;
  return
end
  
sourcelist = {};
indexlist = [];
for src=f.datain
  [t, r] = strtok(src{:},'(');
  sourcelist{end+1} = t;
  if isempty(r)
    indexlist(end+1) = 0;
  else
    indexlist(end+1) = str2num(r);
  end
end

% make sure the common arguments get their input from input
% arguments after the specific ones.

gb_inds = find(strcmp('GETBLOC',sourcelist));
inds = indexlist(gb_inds);
num_gb_inds = max([0 inds]);

input_inds = [];
for n = 1:length(f.comdata)
  if ischar(f.comdata{n})
    [t,r] = strtok(f.comdata{n},'(');
    if any(strcmp(t,{'LOAD' 'INPUT'}))
      input_inds(end+1) = n;
    end
  end
end
inputs = unique(f.comdata(input_inds));

ind = length(inputs)+num_gb_inds+1;
if nargin==4 
  ind = varargin{1};
  if ind<=num_gb_inds | ind > length(inputs)+num_gb_inds+1
    error('not a valid index.');
  end
end

f.comdata{end+1} = [data '(' int2str(ind) ')'];
