function varargout_puzzle

    nouts = [];
    
    function varargout = manyout
        varargout = num2cell(1:ceil(rand*10));
        nouts = numel(varargout);
    end

    [out{1:5}] = manyout(); %Fix this line
    
    if exist('out', 'var') && iscell(out) &&...
       (numel(out) == nouts) && all(cell2mat(out) == 1:nouts)
        disp pass
    else
        disp fail
    end
end