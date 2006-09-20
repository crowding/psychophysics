function this = Identifiable
    %A reasonably unique string identifier for objects.
    persistent number;
    persistent datestr;
    
    if isempty(number)
        %a serial number with the date the serial number series started
        number = 0; 
        datestr = sprintf('%04d-%02d-%02d__%02d-%02d-%02d', floor(clock));
    end
        
    %Identifiable is a mixin class that carries a serial number accessible
    %using id().
    this = inherit(properties('id', sprintf('%s_%d', datestr, number)), public(@setId));
    
    number = number + 1;
    function setId(value)
        error('Identifiable:readOnly', 'IDs are not modifiable');
    end
        
end