function this = Quest(varargin)
    %An object interface to the Pschtoolbox QUEST functions.
    %
    %the 'e' method selects stimulus values according to The QUEST
    %algorithm.
    %
    %Set the 'criterion' to an evaluable object (see 'ev') to determine
    %what counts as 'yes' or 'no.' It should return 1(yes), -1(no) or 0(no
    %action.)
    %
    %Set the 'restriction' to an evaluable object (see 'ev') to determine
    %what actual stimulus values are returned (e.g. limiting within
    %physical parameters, or a particular stimulus set.)
    %
    %Configure the properties to set the prior distribution.
    %
    %After the experiment is over, the results should be found in the data
    %dump of this object.
    
    %the criterion for correct detection...
    criterion = TrialSuccessful();
    
    %if there is a restriction to enforce on the generated trials, try it
    %here...
    restriction = Identity();
    
    %these are the parameters used to initialize the priors for QUEST.
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
        %last stimulus value that was used.
        
        response = criterion(trial, result);
        if response ~= 0
            q = QuestUpdate(q, valueUsed, response > 0);
        end
    end

    function v = e(trial)
        %returns the Quest algorithm's current recommendation for a
        %stimulus value...
        
        if isempty(q)
            q = QuestCreate(guess, guessSD, pThreshold, beta, delta, gamma, grain, range);
            q.updatePdf = 1;
            q.normalizePdf = 1;
        end
        
        v = QuestQuantile(q);
        
        %grab a value...
        v = ev(restriction, v);
    end
end