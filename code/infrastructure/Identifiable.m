function this = Identifiable
    %Identifiable is a mixin class that carries a serial number accessible
    %using id().
    this = public(@id);
    
    persistent number;
    if isempty(number)
        number = 1;
    end
        
    id_ = number;
    number = number + 1;
    
    function out = id
        out = id_;
    end
end