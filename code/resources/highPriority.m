function i = highPriority(varargin)
%returns an initializer for setting high CPU priority. Expects a named
%argument 'window' for the window number.
%
%Optional named argument 'priority' to set a priority less than the
%maximum.
%
%Outputs fields 'priority and 'oldpriority'.
i = currynamedargs(@initializer, varargin{:});

    function [r, o] = initializer(o)
        
        if ~isfield(o, 'priority')
            o.priority = MaxPriority(o.window);
        end
        
        o.oldpriority = Priority(o.priority);
        
        r = @release;
        
        function release
            Priority(o.oldpriority);
        end
    end
end