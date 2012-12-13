%A defaults system, allowing you to override defaults that were set in
%the class files themselves. The defaults are set on object
%instantiation, before initializer arguments are set. You may "push"
%and "pop" the current defaults onto a stack, to transiently modify
%defaults.
%
%Think of it as dynamically scoped variables.
%
%the first time defaults() is run, it looks up defaults functions for the
%computer you are on.
%
%machinedefaults_machinename.m

function out = defaults(command, varargin)
    % it's a struct of structs.
    persistent defaults;

    % a stack on which to save and restore previous defaults...
    persistent defaults_stack;
    persistent defaults_stack_depth; % for robustness...

    if isempty(defaults_stack)
        defaults_stack = {};
        defaults_stack_depth = 0;
    end

    persistent commands;
    if isempty(commands)
        commands = struct('set', @set, 'get', @get, 'exists', @exists, 'remove', @remove);
    end

    if isempty(defaults)
        defaults = struct();
        defaults_global();
        %look up local machine defaults, see if they exist, and execute the
        %script.
        c = Screen('Computer');
        f = str2func(['defaults_' c.machineName]);
        if ~isempty(functions(f))
            f();
        end
    end

    if ~exist('command', 'var')
        command = 'get';
    end

    %dispatch commands
    commands.(command)(varargin{:});

    %this is the only way to make the printing behavior consistent.
    %assigning to out from an inner function didn't work...
    if exist('ans', 'var')
        out=ans;
    end

    function set(varargin)
        defaults = doSet(defaults, varargin{:});
    end

    function def = doSet(def, varargin)
        switch(nargin)
            case {0 1 2}
                error('not enough arguments');
            case 3
                def.(varargin{1}) = varargin{2};
            otherwise
                if ~isfield(def, varargin{1})
                    def.(varargin{1}) = struct();
                end
                def.(varargin{1}) = doSet(def.(varargin{1}), varargin{2:end});
        end
    end

    function got = get(varargin)
        got = doGet(defaults, varargin{:});
    end

    function got = doGet(def, varargin)
        switch(nargin)
            case 0
                error('not enough arguments');
            case 1
                got = def;
            case 2
                got = def.(varargin{1});
            otherwise
                got = doGet(def.(varargin{1}), varargin{2:end});
        end
    end

    function e = exists(varargin)
        e = doExists(defaults, varargin{:});
    end

    function e = doExists(def, varargin)
        switch nargin
            case {0 1}
                error('not enough arguments');
            case 2
                e = isfield(def, varargin{1});
            otherwise
                e = doExists(def.(varargin{1}), varargin{2:end});
        end
    end

    function remove(varargin)
        defaults = doRemove(defaults, varargin{:});
    end

    function def = doRemove(def, varargin)
        switch nargin
            case {0 1}
                error('not enough arguments');
            case 2
                def = rmfield(def, varargin{1});
            otherwise
                def.(varargin{1}) = doRemove(def.(varargin{1}), varargin{2:end});
        end
    end

    function push_()
        %push and pop should be fairly fast because of persistent vars and
        %copy-on-write.
        defaults_stack = {defaults defaults_stack};
        defaults_stack_depth = defaults_stack_depth + 1;
    end

    function pop_()
        defaults = defaults_stack{1};
        defaults_stack = defaults_stack{2};
        defaults_stack_depth = defaults_stack_depth - 1;
    end
end