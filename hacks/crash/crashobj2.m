function this = crashobj2(a_)
    this = autoobject();
    this = rmfield(this, {'property__', 'method__', 'version__'});
    
%{
    function a_ = getA()
        a_ = a;
    end

    function setA(a_)
        a = a_;
    end
%}
end