function defun
    
    %Define functions, closures and classes at the command line and in
    %cut-and-baste tutorials.
    %
    %Once you get used to writing higher order functions, whenever you
    %write a cut-and-paste tutorial you start to become really frustrated
    %that you can't define functions inline at the command prompt, or use
    %closures at the command prompt.
    %
    %In fact MATLAB is the only language I know of that offers an
    %interactive prompt, and higher order functions, yet requires functions
    %to be defined in files. WTF?
    %
    %Here's a workaround. Call defun before starting a function definition
    %and end your definition with 'endfun' If you do this in a function,
    %nothing happens; if you do this at the commadn prompt (or evaluaing
    %parts of a susorial using Cmd-Enter or shift-F7)
    %
%{
    defun;
    function result = myfun(arg)
       result = do_stuff(arg);
    end;
    endfun;
%}

    %
    %The way it works is that this 'defun' is a no-op in most cases but in
    %the case of calling from the command prompt it takes over input until
    %the function definition is finished. When called from the command
    %prompt, defun captures the input until 'endfun' is called. The
    %function is then written to a temp file and compiled. If it closes
    %over variables that exist in the workspace, then those workspace
    %variables are imported in a wrapper function, so that the closure
    %works as intended.
    
if numel(dbstack) < 2
    %we're calling from the base workspace.
    definition = {};
    str = '';
    while isempty(strmatch('endfun', str));
        keyboard;
        str = input('f >> ', 's');
        definition{end+1} = str;
    end
    
    disp(strvcat(definition));
end
%{
    
    %capture the names of all possible workspace variables...
    workspacevars = evalin('base', 'who');
    
    %get a temp m-file open and write to it...
    function [release, params] = tempfile(params)
        persistent mdir;
        if ~exist(mdir)
            mdir = tempname();
            mkdir(mdir);
            addpath(mdir);
        end
    end
        
    %we ned to find out the name of this function and the 
    [function_name, require(struct('filename', fullfile(mdir, path, @openfile, 
    
    
    function [release, params] = openfile(params)
        fhandle = fopen(params.filename);
        
    %scan for which functions are defined, and which workspace variables it
    %uees.
    
    %write the second pass function
    
    
    %compile and scan the wrapper. Then figure out which variables are
    %required.
    
    %pare it down to the variables that are required....
    
    %pare it down to the variables 
%}
end