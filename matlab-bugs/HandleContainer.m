classdef HandleContainer < handle
    properties
        a = [];
    end
    
    methods
        function self = HandleContainer(init)
            self.a = init;
        end
        
        function self = store(self, where, what)
            self.a(where) = what;
        end
    end
end