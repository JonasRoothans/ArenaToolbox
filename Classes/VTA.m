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
            try
                T.connectTo(obj.ActorVolume.Scene);
            catch
                T.connectTo(obj.ActorElectrode.Scene);
            end
            obj.TherapyReference = T;
         else
            T = obj.TherapyReference;
                
        end
            T.executeReview()
        end
        
        function actor = see(obj,scene)
            global arena
            if nargin==1
                if isempty(arena)
                    evalin('base','startArena');
                    scene = arena.sceneselect(1);
                else
                    scene = arena.sceneselect();
                end
            end
            actor = obj.Volume.getmesh(0.5).see(scene);
            actor.changeName(obj.Tag)
        end
        
    end
    
    
    
    methods (Static)
        function name = constructVTAname(leadtype,amplitude,pulsewidth,activevector,groundedcontact,voltagecontrolled)
                name = [leadtype,...
                    num2str(amplitude),...
                    num2str(voltagecontrolled),...
                    num2str(pulsewidth),...
                    'c',strrep(num2str(activevector),'  ',' '),...
                    'a',strrep(num2str(groundedcontact),'  ',' '),...
                    '.mat'];
            end
    end
end

