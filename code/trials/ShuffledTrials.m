function this = ShuffledTrials(varargin)
    defaults = struct('trialList', {{}});

    this = Object(...
        propertiesfromdefaults(defaults, 'params', varargin{:}),...
        public(@hasNext, @next, @result));
    
    
    function has = hasNext()
        has = ~isempty(this.trialList);
    end


    function out = next
        index = floor(rand * numel(this.trialList));
        out = this.trialList{index};
        this.trialList{index} = [];
    end


    function result(last)
        %re-shuffle the trial if it was not successful
        if ~last.successful
            this.trialList{end+1} = last
        end
    end
end