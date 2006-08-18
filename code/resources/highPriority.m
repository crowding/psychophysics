function i = highPriority(varargin)
%returns an initializer for setting high CPU priority. Expects a CPU
%argument 'window' for the window number.
i = setnargout(2, currynamedargs(@initializer, varargin{:}));

    function [r, o] = initializer(o)
        max = MaxPriority(o.window);
        old = Priority(max);

        r = @release;

        function release
            Priority(old);
        end
    end
end

