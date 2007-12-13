function [push, readout] = linkedlist(dim)
%godawful function to record a list of data (e.g. streaming eye position or other
%streaming input data) in memory.

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

    function out = doReadout(what)
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
