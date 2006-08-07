function this = properties(varargin)
    %creates a properties object. The initializations arguments are as in 
    %STRUCT, with the exception that cell arguments are not split across
    %several structures. (matlab certainly does not follow the Princlple
    %of Least Astonishment
    
    %wrap cells in singleton cells - to undo the 'astonishing' behavior of
    %matlab's STRUCT
    whichcells = cellfun(@iscell, varargin);
    varargin(whichcells) = cellfun(@(x) {x}, varargin(whichcells), 'UniformOutput', 0);
    
    %make the core structure
    core = struct(varargin{:});
    names = fieldnames(core);

    %make accessors
    accessors = cellfun(@make_accessor, names, 'UniformOutput', 0);
    function fn = make_accessor(name)
        fn = @accessor;
        function val = accessor(val)
            if (nargin == 0)
                %switching on nargin is ugly, but saves on
                %accessor namespace
                val = core.(name);
            else
                core.(name) = val;
            end
        end
    end
    accessors = cell2struct(accessors, names, 1);

    this = publicize(accessors); 
    %the structure winds up being a little more indirected than with
    %writing the accessors directly.
end