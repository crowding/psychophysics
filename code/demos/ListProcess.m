function this = ListProcess(varargin)

%simply takes a list of sequential outputs adn returns them for each
%call...

list = {};
index = 1;
varargin = assignments(varargin, 'list'); %hmmm... assignments would be better if it called setters...
persistent init__
this = autoobject(varargin);

    function reset()
        index = 1;
    end

    function [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11] = next()
        if (index <= size(list, 2))
            [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11] = list{:,index};
            index = index+1;
        else
            [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11] = deal([]);
        end
    end

end