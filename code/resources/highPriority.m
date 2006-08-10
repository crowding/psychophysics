function i = highPriority(screen)
i = @initializer;

    function r = initializer
        old = Priority();
        max = MaxPriority(screen);
        Priority(max);

        r = @release;

        function release
            Priority(old);
        end
    end
end

