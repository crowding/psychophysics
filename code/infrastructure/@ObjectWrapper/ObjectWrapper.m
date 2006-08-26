function this = ObjectWrapper(object)
    %take an object (which whould be a function-handled struct, etc.) and wrap it up with an
    %object so that you get fun things like operator overloading, load/save
    %wrappers, and so on without having to write it as a MATLAB object.
    
    this.wrapped = object;
    this = class(this, 'ObjectWrapper');
end