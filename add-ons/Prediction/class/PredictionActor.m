classdef PredictionActor < ArenaActor
    %PREDICTIONACTOR is a help class that it is possible to delete the
    %class ArenaActor
    
    properties
    end
    
    methods
        function obj = PredictionActor()
                %This needs to be inside here!
        end
        
        function delete(obj)
            delete@handle(obj)
        end
    end
end

