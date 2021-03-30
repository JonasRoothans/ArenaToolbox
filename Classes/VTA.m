classdef VTA < handle
    %VTA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Electrode %[electrode]
        Volume %[VoxelData]
        Source  %[Suretune portal]
        ActorElectrode %[actor]
        ActorVolume %[actor]
        Space  = Space.Unknown;
    end
    
    
    methods
        function obj = VTA()
            %VTA Construct an instance of this class
            %   Detailed explanation goes here
           
        end
        
    end
end

