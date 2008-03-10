function [] = set(obj,prop,value)
  
  if ismember(prop,fieldnames(obj))
    eval(['obj.' prop '=value;']);
  else 
    error ('This property does not exist in PMBLOCK')
  end
  
  assignin('caller', inputname(1), obj)
