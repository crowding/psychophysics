function esc = shellquote(string)
    %Make a string that will be interpreted as a literal string in
    %e.g. shell script.
    esc = regexprep(string, '''', '''\\''''');
    esc = strcat('''', esc, '''');
end
