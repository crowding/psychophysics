function initializer = warningState(state, identifier)
    initializer = @init;
    
    function [release, params] = init(params)
        prevState = warning('query', identifier);
        warning(state, identifier);
        release = @unset;
        
        function unset()
            warning(prevState.state, prevState.identifier);
        end
    end
end