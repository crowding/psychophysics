function init = listenChars(varargin);

    %returns an initializer for ListenChar
    init = currynamedargs(@doListen, varargin{:});
    
    function [release, params] = doListen(params)
        %flush buffer
        ListenChar(1);
        FlushEvents();
        
        release = @()ListenChar(0);
    end
end