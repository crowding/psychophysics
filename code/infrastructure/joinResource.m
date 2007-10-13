function f = joinResource(first, varargin)
%JOINRESOURCE(resource1, resource2, ....)
%takes a set of resource function pointers and chains them together so that
%they can be used as a single argument to REQUIRE, with releases happening
%in reverse order from initializations.
%
%The optional outputs of the first initializer
%are passed into the input of the second initializer, and so on.
%This lets you successively build up an operation with reversible
%components. The output of the final initializer is passed to the body
%function.

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
        
        %return a function closing over the initializers, taking the output
        %from the rest of the arguments
        f = @joinedInitializer;
    end
    
    
    %The 2-initializer join: This is chained together to make N-initializer
    %joins.
    %
    %The function executes the first initializer, pass its result to the
    %second, executes the second, and returns the result of the second.
    %
    %It returns a releaser which releases the second initializer before the
    %first.
    %
    %If there is a problem with the second initializer, it releases the
    %first.
    
    function [r, details] = joinedInitializer(details)
        %A handle to this function is the combined initializer.
        [release1, pass] = first(details);
        try
            [release2, details] = rest(pass);
        catch
            e = lasterror;
            try
                release1();
            catch
                e = adderror(lasterror, e); %chain the exception
            end
            rethrow(e);
        end
        
        %return the releaser
        r = @joinedReleaser;

        function joinedReleaser
            try
                release2();
            catch
                err = lasterror;
                try
                    release1();
                catch
                    err = adderror(lasterror, err); %chain exception
                end

                rethrow(err);
            end
            release1();
        end
    end
end
