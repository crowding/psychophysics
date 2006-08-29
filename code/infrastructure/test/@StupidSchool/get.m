function v = get(this, name)
switch name
    case 'prop'
        v = this.prop;
    otherwise
        error();
end
end