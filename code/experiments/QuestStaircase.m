function this = QuestStaircase(varargin)
    %Selects stimulus values according to a QUEST function.
    %After the experiment is over, the results should be found in the data
    %dump of this object.
    %Configure the initial values to set the prior distribution.
    
    %the criterion is a function/evaluatable object that returns -1, 0, or
    %1 (1 being a 'yes' and -1 being a 'no' in e.g. detection experiments.)
    
    %the criterion for correct detection...
    criterion = TrialSuccessful();
    
    %if there is a restriction to enforce on the generated trials, try it
    %here...
    restriction = Identity();
    
    %these are the parameters use dto initialize the priors for QUEST.
    guess = 0;
    guessSD = 4;
    pThreshold = .82;
    beta = 3.5;
    delta = 0.01;
    gamma = 0.5;
    grain = 0.01;
    range = 5;
    
    %the actual quest structure is initialized from the above values.
    q = [];

    persistent init__;
    this = autoobject(varargin{:});
    
    function result(trial, result, valueUsed)
        %update the quest estimate using the recent trial result and the
        %stimulus value that was used.
        
        response = criterion(result);
        if response ~= 0
            q = QuestUpdate(q, valueUsed, response > 0);
        end
    end

    function v = e(trial)
        %returns the Quest algorithm's current recommendation for a
        %thing...
        
        if isempty(q)
            q = QuestCreate(guess, guessSD, pThreshold, beta, delta, gamma, grain, range);
            q.updatePdf = 1;
            q.normalizePdf = 1;
        end
        
        v = QuestQuantile(q);
        
        %grab a value...
        v = ev(restriction, v);
    end

    function 

end