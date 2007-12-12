function this = RewardTestTrial(varargin)
    
    persistent init__;
    this = autoobject(varargin{:});
    
    function [params, result] = run(params)
        result = struct('success', 1);
        
        rect = FilledRect([-50 0 50 50], 0, 'visible', 1);
        trigger = Trigger();
        reward = params.input.eyes.reward;
        
        main = mainLoop('graphics', {rect}, 'input', {params.input.eyes}, 'triggers', {trigger});

        trigger.singleshot(atLeast('y', 0), @up);
        trigger.singleshot(atLeast('next', 0), @setEnd);
        
        params = main.go(params);
        
        function setEnd(s)
            trigger.singleshot(atleast('next', s.next + 10), main.stop);
        end
       
        function up(s)
            reward(s.refresh, 100);
            %go down
            rect.setRect([-50 -50 50 0]);
            trigger.singleshot(atMost('y', 0), @down);
        end
        
        function down(s)
            reward(s.refresh, 100);
            rect.setRect([-50 0 50 50]);
            trigger.singleshot(atLeast('y', 0), @up);
        end
    end
end