%A defaults system, allowing you to semipermanently (on machine or session
%basis) override defaults that were set in the 
%
%To set defaults:
%machinedefaults_machinename.m

function defaults(command, varargin)
    persistent defaults_struct;
    persistent commands;
    
    if isempty(commands)
        commands = struct('set', @set, 'get', @get, 'exist', @exist);
    end
    if isempty(defaults_struct)
        defaults_struct = struct({});
        %look up local machine defaults, see if they exist, and execute the
        %script
        c = Screen('Computer');
        f = str2func(['defaults_' c.machineName]);
        if ~isempty(fns.file)
            f();
        end
    end

    %dispatch commands
    commands.(command)(varargin{:});
    
    function value = set(class, property, value)
        
    end

    function get(class, property)
        
    end

    function exist(class, property)
        
    end


end