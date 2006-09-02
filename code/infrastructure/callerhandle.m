function h = callerhandle(n)
%Gets a handle to the calling function.
%the optional parameter 'n' says how many stack frames to evalin up, '0'
%being the function that invokes callerhandle. Default is 1 (the caller of
%the function that invokes callerhandle.)

if ~exist('n', 'var')
    n = 1;
end

n = n + 2;
stack = dbstack;
name = stack(n).name;

if name(1) == '@'
    name(1) = [];
else
    name = regexprep(name,'.*[^a-zA-Z0-9]', '');
end

handlecommand = ['@()@' strrep(name, '''', '''''')];

producer = evalinlevel(handlecommand, n);
functions(producer);
h = producer();

    function varargout = evalinlevel(command, n)
        for i = 1:n
            %each stack level gets an evalin -- and quotes get doubled
            command = ['evalin(''caller'', ''', strrep(command, '''', ''''''), ''')'];
        end
        
        [varargout{1:nargout}] = evalin('caller', command);
    end

end

