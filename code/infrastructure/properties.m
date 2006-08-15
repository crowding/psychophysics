function this = properties(varargin)
%creates a properties object. the inheritability is done directly instead
%of via publicize()

%wrap cells in singleton cells - to undo the 'astonishing' behavior of
%matlab's STRUCT
whichcells = cellfun(@iscell, varargin);
varargin(whichcells) = cellfun(@(x) {x}, varargin(whichcells), 'UniformOutput', 0);

%make the core structure
this = struct(varargin{:});
[this, setters] = structfun(@accessor, this, 'UniformOutput', 0);

%also put in property setters as separately named methods (faster than
%checking nargin)
names = fieldnames(this);
setters = struct2cell(setters);
cellfun(@putSetter, names, setters);
    function putSetter(name, setter)
        this.(['set' upper(name(1)) name(2:end)]) = setter;
    end

%this is a behind the scenes object so I will use the ugly boilerplate for
%speed
this.method__ = @method__;
    function val = method__(name, val);
        if nargin > 1
            this.(name) = val;
        else
            val = this.(name);
        end
    end
%that boilerplate did the same job as 'this = publicize(this)' but directly,
%so it is faster.

end