function i = highPriority(screen)
i = @initializer;

    function r = initializer
        max = MaxPriority(screen);
        old = Priority(max);

        r = @release;

        function release
            Priority(old);
        end
    end
end

