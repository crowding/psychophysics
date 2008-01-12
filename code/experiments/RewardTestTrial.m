function this = RewardTestTrial(varargin)
    
    persistent init__;
    this = autoobject(varargin{:});
    
    rewardSize = 75;
    rewardTime = 0.1;
    
    function [params, result] = run(params)
        result = struct('success', 1);
        
        rect = FilledRect([-50 0 50 50], 0, 'visible', 1);
        trigger = Trigger();
        reward = params.input.eyes.reward;
        
        main = mainLoop('graphics', {rect}, 'input', {params.input.eyes}, 'triggers', {trigger});

        trigger.singleshot(atLeast('next', 0), @start);
        
        params = main.go(params);
        
        function start(s)
            trigger.singleshot(atleast('next', s.next + rewardTime), @up);
        end
       
        function up(s)
            reward(s.refresh, rewardSize);
            %go down
            rect.setRect([-50 -50 50 0]);
            trigger.singleshot(atLeast('next', s.next + rewardSize/1000 + 0.1), main.stop);
        end
    end
end