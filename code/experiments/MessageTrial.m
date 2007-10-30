function this = MessageTrial(varargin)
    message = 'Insert message here. Press space to continue.';
    key = 'Space';
    color = [0 0 0];

    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        
        r = RefreshTrigger();
        t = Text([0 0], message, color, 'centered', 1, 'visible', 1);
        
        main = mainLoop ...
            ( 'graphics', {t} ...
            , 'keyboard', {KeyDown(@endTrial, key)} ...
            , 'triggers', {r} ...
            );
        
        main.go(params);
        
        function endTrial(h)
            result = struct('success', 1, 'keypress', 1);
            t.setVisible(0);
            r.set(main.stop, h.refresh + 1);
        end
    end
end
