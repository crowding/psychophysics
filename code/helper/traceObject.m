function [obj, readout] = traceObject(obj, disp)
%Modifies an object to record/display all calls to it Returns a function
%handle that reads out and clears
if ~exist('disp', 'var')
    disp = 0;
end

[push, readout] = linkedlist(1);

for i = obj.method__()'
    obj.method__(i{:}, makewrapper(obj.method__(i{:})));
end

    function x = makewrapper(fn)
        x = @wrapper;
        function varargout = wrapper(varargin)
            try
                [out{1:nargout}] = fn(varargin{:});
                varargout = out;
                push({fn, varargin, out});
                if disp
                    display(struct('call', {fn}, 'input', {varargin}, 'output', {varargout}));
                end
            catch
                push({{fn}, varargin, {lasterror}});
                if disp
                    display(struct('call', {fn}, 'input', {varargin}, 'error', {lasterror}));
                end
                rethrow(lasterror);
            end
        end
    end

[tmp, obj] = obj.method__();
end

