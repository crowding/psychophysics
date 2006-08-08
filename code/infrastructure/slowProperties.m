function this = slowProperties(varargin)
%creates a properties object. The initializations arguments are as in
%STRUCT, with the exception that cell arguments are not split across
%several structures. (matlab certainly does not follow the Princlple
%of Least Astonishment)
%
%this is the structure I would like to use, 


%wrap cells in singleton cells - to undo the 'astonishing' behavior of
%matlab's STRUCT
whichcells = cellfun(@iscell, varargin);
varargin(whichcells) = cellfun(@(x) {x}, varargin(whichcells), 'UniformOutput', 0);

%make the core structure
this = struct(varargin{:});
this = structfun(@newAccessor, this, 'UniformOutput', 0)
this = publicize(this);

    function fn = newAccessor(value)
        fn = @accessor;
        function v = accessor(v)
            if (nargin > 0)
                value = v;
            else
                v = value;
            end
        end
    end
end