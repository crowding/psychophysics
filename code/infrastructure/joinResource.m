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

    %Recursively define a joined initializer out of the 2-initializer join
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
    
    
    %The 2-initializer join: This is chained together to make N-initializer
    %joins.
    %
    %The function executes the first initializer, pass its result to the
    %second, executes the second, and return the result of the second.
    %
    %It returns a releaser which releases hte second initializer before the
    %first.
    %
    
    function [r, varargout] = joinedInitializer(varargin)
        %This function over variables 'nfirst' and 'nrest' so that it knows
        %how many arguments to expect in output. 
        %a handle to this function is the combined initializer.
        [release1, pass{1:nfirst-1}] = first(varargin{:});
        try
            [release2, varargout{1:nrest-1}] = rest(pass{:});
        catch
            e = lasterror; %FIXME - this path not exercised by unit tests?
            release1(); %FIXME - may need chaining
            rethrow(e);
        end
        
        %return the releaser
        r = @joinedReleaser;

        function joinedReleaser
            try
                release2();
            catch
                err = lasterror;
                %stacktrace(err);  %FIXME - chained errors
                try
                    release1(); %may need chaining
                catch
                    %stacktrace(err);  %FIXME - chained errors
                    err = lasterror;
                end
                rethrow(err);
            end
            release1();
        end
    end
end