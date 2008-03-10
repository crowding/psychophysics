function out = get (obj,prop)
  
  if ismember(prop,fieldnames(obj))
    out = eval(['obj.' prop]);
  else 
    error ('This property does not exist in PMBLOCK')
  end
  