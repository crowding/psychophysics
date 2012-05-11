function name = getterName(propname)
    name = ['get' upper(propname(1)) propname(2:end)];
end