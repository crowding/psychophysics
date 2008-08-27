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

    function varargout = next()
        if (index <= size(list, 2))
            [varargout{1:numel(list(:,index))}] = list{:,index};
            index = index+1;
        else
            [varargout{1:nargout}] = deal([]);
        end
    end

end