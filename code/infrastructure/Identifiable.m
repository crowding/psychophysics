function this = Identifiable
    %A reasonably unique serial number for objects.
    persistent number;
    
    if isempty(number)
        %the whole number part is a serial number and the fractional part
        %indicates the date the serial number series was started. This
        %should be good enough for our purposes.
        number = str2num(sprintf('.%04d%02d%02d%02d%02d%02d', floor(clock)));
    end
        
    %Identifiable is a mixin class that carries a serial number accessible
    %using id().
    this = public(@getId, @setId);
    this.properties__ = {'id'};
    
    id_ = number;
    number = number + 1;
    
    function out = getId
        out = id_;
    end

    function setId(value)
        error('Identifiable:readOnly', 'IDs are not modifiable');
    end
end