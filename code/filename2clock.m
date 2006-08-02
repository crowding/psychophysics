function out = filename2clock(str)

    bits_per_char = 5;
    bits = [9, 4, 5, 5, 6, 6];

    numbers = arrayfun(@(x)base2dec(x, 32), str);
    bitgroups = arrayfun(@(x)dec2bin(x, bits_per_char), numbers, 'UniformOutput', 0);
    bitstring = strcat(bitgroups{:});
    regroup = strsplit(bitstring, bits);
    out = cellfun(@bin2dec, regroup);
    out(1) = out(1) + 1792;
end

function splits = strsplit(string, lengths)
    %Splits a string into consecutive substrings of the given length.
    %For example:
    %strsplit('squeamish ossifrage', '5 1 6 3 3') gives:
    %{'squeam', 'i', 'ish oss', 'ifr', 'age'}

    %I note this function as an example of how 1-based indexing in matlab
    %with inclusive range designations winds up being annoying.
    %
    %Here a conceptually simple function's implementation is marred by
    %having to compensate for always being off by one.
    %
    %See Edsger Dijkstra's memo at
    % http://www.cs.utexas.edu/users/EWD/ewd08xx/EWD831.PDF
    %for more on this point.

    starts = [1 (cumsum(lengths(1:end-1)) + 1)]; %plus one here, unnecessary with proper indexing
    ends = starts + lengths - 1;           %and minus one here, also would be unnecessary
    splits = arrayfun(@(a, b)string(a:b), starts, ends,'UniformOutput', 0);
end