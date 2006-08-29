function this = set(this, name, value)
switch name
    case 'prop'
        this.prop = value;
    otherwise
        error
end
end
