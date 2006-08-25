function i = highPriority(varargin)
%returns an initializer for setting high CPU priority. Expects a CPU
%argument 'window' for the window number.
i = currynamedargs(@initializer, varargin{:});

    function [r, o] = initializer(o)
        
        if ~isfield(o, 'priority')
            o.priority = MaxPriority(o.window);
        end
        
        old = Priority(o.priority);
        %disp(sprintf('%g->%g', old, o.priority));
        
        r = @release;
        
        function release
            %disp(sprintf('%g->%g', o.priority, old));
            Priority(old);
        end
    end
end

