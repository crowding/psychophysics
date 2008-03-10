%DELCOMINPUT Deletes a common input definition from a pmfun
%   F = DELCOMINPUT(F,NAME) Deletes the common input with the name NAME
%   from the pmfun definition and updates all other fields of the pmfun
%   in consequence.
%
%   F = DELCOMINPUT(F,IND) Deletes the common input at index IND in the
%   pmfun definition and updates all other fields of the pmfun in
%   consequence.
%
%   Example:
%      f = pmfun;
%      f = addcominput(f,'ref_img','LOAD');   % loads from 1st file
%      f = addcominput(f,'ref_param','LOAD') % loads from 2nd file
%      f = delcominput(f,'ref_img') % remove 1st file reference
%                                   % The 2nd is then shifted to 1st.
%
%   See also: ADDCOMINPUT, ADDSPECINPUT, DELSPECINPUT, ADDOUTPUT, DELOUTPUT.
       
function f = delcominput(f,var)

if isa(var,'double')
  dataind = var;
  if dataind > length(f.argin)
    error('The common input does not contain that many entries (comarg).')
  end
elseif ischar(var)
  dataind = find(strcmp(var, f.comarg));
  if isempty(dataind)
    error('no variable exists with that name in function definition (comarg).')
  end
else
  error('second argument must be either a double or a string');
end
	
f.comarg(dataind) = [];
input = f.comdata{dataind};
f.comdata(dataind) = [];
if ischar(input)
  [t,r] = strtok(input,'('); % r = a string describing the index.
  if any(strcmp(t,{'INPUT' 'LOAD'}))
    inp_ind = str2num(r);
    
    % make a list of all common data that accesses the dispatcher input.
    datalist = {}; % the type of data
    inp_indlist = []; % the index of the disp. input that it accesses.
    dataindlist = []; % the indices into the comdata.
    for n=1:length(f.comdata)
      if ischar(f.comdata{n})
	[t, r] = strtok(f.comdata{n},'(');
	if ~isempty(r) & any(strcmp(t,{'LOAD' 'INPUT'}))
	  datalist{end+1} = t;
	  inp_indlist(end+1) = str2num(r);
	  dataindlist(end+1) = n;
	end
      end
    end
    if ~ismember(inp_ind,inp_indlist);
      higher = (find(inp_indlist>inp_ind));
      for ind = higher
	f.comdata{dataindlist(ind)}= ...
	    [datalist{ind} '(' int2str(inp_indlist(ind)-1) ')']; 
      end
    end
  end
end

