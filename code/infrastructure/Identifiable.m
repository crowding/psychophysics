function this = Identifiable(varargin)
    %A reasonably unique string identifier for objects.
    persistent number_;
    persistent datestr_;
    
    if isempty(number_)
        %a serial number with the date the serial number series started
        number_ = 0; 
        datestr_ = sprintf('%04d-%02d-%02d__%02d-%02d-%02d', floor(clock));
    end

    id = sprintf('%s_%d', datestr_, number_);

    persistent init__;
    this = autoobject(varargin{:});
    number_ = number_ + 1;

    %Identifiable is a mixin class that carries a serial number accessible
    %using id().

    function setId(value)
        error('Identifiable:readOnly', 'IDs are not modifiable');
    end
    
    function value = getId()
        value = id;
    end
end