function f = joinResource(first, varargin)
%JOINRESOURCE(resource1, resource2, ....)
%takes a set of resource function pointers and chains them together so that
%they can be used as a single argument to REQUIRE, with releases happening
%in reverse order from initializations.
%
%The way initializers are called is different from what happens when you
%pass multiple arguments
%to REQUIRE.
%
%In the case of JOINRESOURCE, the optional outputs of the first initializer
%are passed into the input of the second initializer, and so on.
%This lets you successively build up an operation with reversible
%components. The output of the final initializer is passed to the body
%function.
%For instance, opening a file and resizing it:
%
%filename = 'test.file'
%size = 100;
%require(joinResource(openFile, resizeFile))
%function [close, fid] = openFile:
%   fid = fopen(filename);
%   close = close(fid);
%end

    if (nargin == 1)
        %one resource does not need to be joined
        f = first;
    elseif (nargin < 1)
        error('joinResource:illegalArgument', 'need at least one argument')
    else % (nargin > 1)
        %multiple resources, join by recursion
        rest = joinResource(varargin{:});
        
        nfirst = nargout(first);
        nrest = nargout(rest);
        
        if nfirst < 1
            error('joinResource:illegalArgument', ...
                'Initializers need at least 1 output (and not varargout)');
            %the rest of the initializers are checked in the recursion
        end
        
        %return a function closing over the initializers, taking the output
        %from the rest of the arguments
        f = setnargout(nargout(rest), @joinedInitializer);

    end
    
    function [r, varargout] = joinedInitializer(varargin)
        %a handle to this function is the combined initializer.
        [release1, pass{1:nfirst-1}] = first(varargin{:});
        try
            [release2, varargout{1:nrest-1}] = rest(pass{:});
        catch
            release1();
        end
        
        %return the releaser
        r = @joinedReleaser;

        function joinedReleaser
            try
                release2();
            catch
                err = lasterror;
                release1();
                rethrow(err);
            end
            release1();
        end
    end
end