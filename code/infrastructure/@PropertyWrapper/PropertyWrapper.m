function this = PropertyWrapper(getter, setter)
    this.getter = getter;
    this.setter = setter;
    
    this = class(this, 'PropertyWrapper');
end