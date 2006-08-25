function delayedSaccade()
trialOptions = struct();

require(setupEyelinkExperiment(), @runExperiment);
    function runExperiment(details)
        if details.dummy
            trialOptions.timeDilation = 3;
        end

        for i = 1:10
            trial = SaccadeToTarget(trialOptions);
            trial.run(details);
        end
    end
end