function crashme()
    crash1();

    function crash1()
        
        x = crash2();
        x();

        function x = crash2()
            x = evalin('caller', '@() eval(''1'');');
        end
    end
end