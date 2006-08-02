function out = clock2filename(time)

%input is the time stamp from time().
%
%encodes the timestamp accurate to the second in 7 uppercase and/or
%numeric characters. Usable from 1792 through 2303 A.D. The
%resulting string is sortable.
bits_per_char = 5;
bits = [9, 4, 5, 5, 6, 6];

time = fix(time);
time(1) = time(1) - 1792; %i.e. 2048 - 256
%each number to a binary string in a cell array
binstr = arrayfun(@dec2bin, time, bits, 'UniformOutput', 0);

%regroup 5 bits at a time adn  convert to numbers
groups = cellstr(reshape(strcat(binstr{:}), bits_per_char, [])')';
numbers = cellfun(@bin2dec, groups);

%convert numbers to chars and concatenate to a string
out = arrayfun(@(x) dec2base(x, 2.^bits_per_char), numbers);
end