classdef ValueContainer
    properties
        a = [];
    end
    
    methods
        function self = ValueContainer(init)
            self.a = init;
        end
        
        function self = store(self, where, what)
            self.a(where) = what;
        end
    end
end