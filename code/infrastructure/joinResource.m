function f = joinResource(varargin)

global resources__

%JOINRESOURCE(params, resource1, resource2, ....)
%takes a set of resource function pointers and chains them together so that
%they can be used as a single argument to REQUIRE, with releases happening
%in reverse order from initializations.
%
%The optional outputs of the first initializer
%are passed into the input of the second initializer, and so on.
%This lets you successively build up an operation with reversible
%components. The output of the final initializer is passed to the body
%function.

    if isstruct(varargin{1})
        defaults = varargin{1};
        varargin(1) = [];
    else
        defaults = [];
    end

    if numel(varargin) > 1
        f = @joinedResource;    
    elseif numel(varargin) == 1
        f = varargin{1};
    else
        f = @noresource;
    end
    

        
    function [release, params, next] = joinedResource(params)
        if ~isempty(defaults)
            params = namedargs(defaults, params);
        end
        
        if nargout(varargin{1}) > 2
            [release, params, next] = varargin{1}(params);
            varargin{1} = next;
        else
            [release, params] = varargin{1}(params);
            varargin(1) = [];
        end
        
        if numel(varargin) > 1
            next = @joinedResource;
        else
            next = varargin{1};
        end
    end
end

function [release, params] = noresource(params)
    release = @noop;
end