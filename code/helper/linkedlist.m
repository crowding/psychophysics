function [push, readout] = linkedlist(dim)
%function [push, readout] = linkedlist(DIM)
%
%Peter Meilstrup, 2008
%
%Records list of data (e.g. streaming eye position or other
%streaming input data) in memory without the speed penalty of reallocating
%arrays in a loop.
%
%Returns two function handles, 'push', and 'readout', you push data in
%using the pirst, then at the end of your accumulation read it out using
%the second. The accumulated data is concatenated along the dimension DIM.
%
% Example:
%
% >> [push, readout] = linkedlist(2)
% push = 
%     @linkedlist/doPush
% readout = 
%     @linkedlist/doReadout
% >> push([1;2]);
% >> push([3 4;5 6]);
% >> push([0; 0]);
% >> readout()
% ans =
%      1     3     4     0
%      2     5     6     0
     
persistent lists;
persistent counter;

if isempty(lists)
    lists = struct();
    counter = 0;
end

if ~exist('dim', 'var')
    dim = 1;
end

elements = 0;
name = '';

push = @doPush;
readout = @doReadout;

    function doPush(what)
        if isempty(name)
            name = ['t' num2str(counter)];
            counter = counter +1;
            lists.(name) = {};
            elements = 0;
        end
        lists.(name) = {lists.(name) what};
        elements = elements + 1;
    end

    function out = doReadout()
        if ~isempty(name)
            l = lists.(name);
            lists = rmfield(lists, name);
            name = '';
        else
            l = {};
        end
        if ~isempty(l)
            out = cell(1, elements);
            for i = elements:-1:1
                out{i} = l{2};
                l = l{1};
            end
            out = cat(dim, out{:});
        else
            out = [];
        end
    end
end
