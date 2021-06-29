classdef VTA < handle
    %VTA Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TherapyReference
        Electrode %[electrode]
        Volume %[VoxelData]
        Source  %[Suretune portal]
        ActorElectrode %[actor]
        ActorVolume %[actor]
        Space  = Space.Unknown;
        SuretuneStimplan %[stimplan]
        Tag = 'vta without name'
        Settings 
    end
    
    
    methods
        function obj = VTA()
            %VTA Construct an instance of this class
            %   Detailed explanation goes here
           
        end
        
       
        
        function obj = connectTo(obj,scene)
            scene.VTAstorage(end+1) = obj;
        end
        
        function p =  prediction(obj)
            %convert VTA to therapy
            if isempty(obj.TherapyReference)
                T = Therapy(obj.Tag);
                T.connectTo(obj.ActorVolume.Scene)
                T.addVTA(obj);
                obj.TherapyReference = T;
            else
                T = obj.TherapyReference;
                
            end
                
            
            %run prediction on therapy
            p= T.executePrediction();
        end
        
        function printInfo(obj)
            fprintf('---\nVTA: \t\t %s \n',obj.Tag);
            if not(isempty(obj.SuretuneStimplan))
                fprintf('Origin: \t %s\n','Suretune');
                fprintf('Label: \t\t %s \n',obj.SuretuneStimplan.label);
                fprintf('Voltage: \t %s \n',obj.SuretuneStimplan.voltageBasedStimulation);
                fprintf('Amplitude: \t %2.1f \n',obj.SuretuneStimplan.stimulationValue);
                fprintf('Frequency: \t %d \n',obj.SuretuneStimplan.pulseFrequency);
                fprintf('Pulsewidth: \t %d \n',obj.SuretuneStimplan.pulseWidth);
                fprintf('Active: \t %s \n',obj.SuretuneStimplan.activeRings);
                fprintf('Ground: \t %s \n',obj.SuretuneStimplan.contactsGrounded);
                fprintf('Lead type: \t %s \n',obj.SuretuneStimplan.lead.leadType);
                fprintf('Lead label: \t %s \n',obj.SuretuneStimplan.lead.label);
            end
            fprintf('Space: \t\t %s \n',obj.Space)
            
            
        end
        
        function obj = review(obj)
         if isempty(obj.TherapyReference)
            %convert VTA to therapy
            T = Therapy(obj.Tag);
            T.addVTA(obj);
            T.connectTo(obj.ActorVolume.Scene);
            obj.TherapyReference = T;
         else
            T = obj.TherapyReference;
                
        end
            T.executeReview()
        end
        
    end
end

