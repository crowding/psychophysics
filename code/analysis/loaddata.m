function out__ = loaddata(filename__, runConstructors__)
    %load a text datafile produced by a dump() operation.
    
    if nargin < 2
        runConstructors__ = 0;
    end

    %loads data from a file in the dump format. Ignores constructors.
    %
    %note why this logic is not done with require: I need to eval and assign
    %variables in this workspace. This is also the reason for all the
    %double underscores on local variables.
    %
    %check for a compressed file...
    
    [s__, type__] = system(sprintf('file -ib "%s"', filename__));
    if strfind(type__, 'gzip')
        %it's a compressed file, pipe it through gzip
        
        %pipename__ = tempname();
        %[s__, return__] = system(sprintf('mkfifo %s; gunzip -c %s > %s &', pipename__, filename__, pipename__));
        
        %Ha! The above doesn't work. matlab reads two characters ino the
        %next line and discards them (i suppose it rewinds on regular files?)
        %instead of actually READING UNTIL NEWLINE.
        
        [s__, contents__] = system(sprintf('gunzip -c "%s"', filename__));
        
    else
        fid__ = fopen(filename__, 'r');
        contents__ = fread(fid__, inf, 'uchar=>char')';
        fclose(fid__);
    end
    
    for line__ = splitstr(sprintf('\n'), contents__)'
        line__ = line__{1}; %#ok
        
        %printf('%s', line__);
        
        %if line__ == -1
        %    break;
        %end

        if regexp(line__, '^[^\s]* = ')
            %an assignment, it is a bit of data
            if strfind(line__, ' = ')
                %if it's a constructor call...
                if regexp(line__, '^(.+)\s*=\s*[\w/]+\(\s*\1\s*\)')
                    if runConstructors__
                        line__ = regexprep(line__, '^(.+)\s*=\s*(\w+)\(\s*\1\s*\)'...
                            , '${context_}$1 = $2(${context_}$1)');
                        eval(line__);
                    end
                else
                    eval(line__);
                end
            end
        else
            noop();
        end
    end

    vars__ = who;
    for i__ = vars__'
        if numel(i__{1}) < 2 || ~streq(i__{1}(end-1:end), '__')
            if nargout < 1
                assignin('caller', i__{1}, eval(i__{1}));
            else
                out__.(i__{1}) = eval(i__{1});
            end
        end
    end
            
end