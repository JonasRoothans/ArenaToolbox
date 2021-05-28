classdef Therapy < handle
    %THERAPY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        VTAs = VTA.empty;
        Predictions = Prediction.empty;
        Tag
    end
    
    methods
        function obj = Therapy(Tag)
            %THERAPY Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==1
                obj.Tag = Tag;
            end
        end
        
        function obj = addVTA(obj,VTA)
            for i = 1:numel(VTA)
                if isa(VTA(i),'VTA')
                    obj.VTAs(end+1) = VTA(i);
                end
            end
            
        end
        
        function obj = connectTo(obj,scene)
            scene.Therapystorage(end+1) = obj;
        end
        
        
        function p =  executePrediction(obj,heatmap)
            global predictionmanager
            if nargin==1
                p = predictionmanager.newPrediction(obj);
            else
                p = predictionmanager.newPrediction(obj,heatmap);
            end
            obj.Predictions(end+1) = p;
            
            
        end
        
        
        function obj = executeReview(obj)
            %check available electrodes:
            Electrode_list = {obj.VTAs(:).Electrode};
            Electrode_present = not(cellfun(@isempty,{obj.VTAs(:).Electrode}));
            
            %throw error if lead objects are missing.
            if sum(Electrode_present)<numel(Electrode_list)
                msg = sprintf('- %s\n', obj.VTAs(not(Electrode_present)).Tag);
                error([sprintf('The following VTAs did not contain an electrode:\n'),msg])
            end
            
            %connect VTA pool
            global arena
            if not(isfield(arena.Settings,'VTApool'))
                waitfor(msgbox('Your config file is outdated. Please delete config.mat and fully close MATLAB. At next use Arena will run the installation menu'))
                return
            end
            
            %ask for heatmap/model
            global predictionmanager
            heatmap = predictionmanager.selectHeatmap();
            
            %Ask for mode
            options = {'60 us - 1,2,3,4,5 mA - MDT3389'};
            answer = listdlg('PromptString','Select monopolar review preset (can be updated in Therapy.m):','ListString',options,'ListSize',[400,100]);
            switch options{answer}
                case '60 us - 1,2,3,4,5 mA - MDT3389'
                    leadtype = {'Medtronic3389'};
                    voltagecontrolled = {'False'};
                    pulsewidths = {60};
                    amplitudes = num2cell(1:5);
                    contacts = num2cell(1:4);
                otherwise 
                    keyboard
            end 
            
            %define VTAnames        
            [VTAnames,settings] = generateVTAnames(leadtype,amplitudes,pulsewidths,voltagecontrolled);
            
            %pair up VTAs
            if sum(Electrode_present)==2
                [a,b] = meshgrid(1:length(VTAnames),1:length(VTAnames));
                pairs = [a(:),b(:)];
            else
                pairs = (1:length(VTAnames))';
            end
            
            output = [];
            comments = {};
            %Loop over pairs
            for iPair = 1:length(pairs)
               thisPair = pairs(iPair,:);
               if length(thisPair)==2
                   electrode1 = obj.VTAs(1).Electrode;
                   electrode2 = obj.VTAs(2).Electrode;
                   
                   vtaname1 = VTAnames{thisPair(1)};
                   vtaname2 = VTAnames{thisPair(2)};
                   
                   vta1 = electrode1.makeVTA(vtaname1);
                   vta1.Space = obj.VTAs(1).Space;
                   
                   vta2 = electrode2.makeVTA(vtaname2);
                   vta2.Space = obj.VTAs(2).Space;
                   
                   newTherapy = Therapy;
                   newTherapy.addVTA(vta1);
                   newTherapy.addVTA(vta2);
                   
                   p = newTherapy.executePrediction(heatmap);
                   output(thisPair(1),thisPair(2)) = p.Output;
                   comments{thisPair(1),thisPair(2)} = p.Comments;
               else
               end
            end
            
            
        keyboard

                    
                                    
            function [VTAnames,Settings] = generateVTAnames(leadtype,amplitudes,pulsewidths,voltagecontrolled)
                VTAnames = {};
                Settings = [];
                i = 0;
                for iLeadType = 1:numel(leadtype)
                    thisLeadType = leadtype{iLeadType};
                    for iPulseWidth = 1:numel(pulsewidths)
                        thisPulseWidth = pulsewidths{iPulseWidth};
                        for iVoltageControlled  = 1:numel(voltagecontrolled)
                            thisVoltageControlled = voltagecontrolled{iVoltageControlled};
                            for iContact = 1:4
                                for iAmplitude = 1:numel(amplitudes)
                                    thisAmplitude = amplitudes{iAmplitude};
                                    i = i+1;
                                    thisContact = iContact;
                                    activecontact = [0 0 0 0];
                                    activecontact(thisContact) = 1;
                                    groundedcontact = [0 0 0 0];
                                    
                                    
                                    
                                    
                                    VTAnames{i} = constructVTAname(...
                                        thisLeadType,...
                                        thisAmplitude,...
                                        thisPulseWidth,...
                                        activecontact,...
                                        groundedcontact,...
                                        thisVoltageControlled);
                                    
                                    
                                    Settings(i).amplitude = thisAmplitude;
                                    Settings(i).leadtype  = thisLeadType;
                                    Settings(i).pulsewidth = thisPulseWidth;
                                    Settings(i).activecontact = iContact-1;
                                    
                                    
                                end
                            end
                        end
                    end
                end
            end
                                   
            
            function name = constructVTAname(leadtype,amplitude,pulsewidth,activevector,groundedcontact,voltagecontrolled)
                
                name = [leadtype,...
                    num2str(amplitude),...
                    num2str(voltagecontrolled),...
                    num2str(pulsewidth),...
                    'c',strrep(num2str(activevector),'  ',' '),...
                    'a',strrep(num2str(groundedcontact),'  ',' '),...
                    '.mat'];
            end
            

            
            keyboard
            
%             contacts = 0:3;
% amplitudes = 1:5;
% [contacts2d,amplitudes2d] = meshgrid(contacts,amplitudes);
% contacts_vector = reshape(contacts2d,1,[]);
% amplitudes_vector = reshape(amplitudes2d,1,[]);
% n = numel(amplitudes_vector);
% for iLead = 1:numel(XLS)
%     %correction
%     XLS(iLead).XLS.Tlead2MNI = XLS(iLead).XLS.Tlead2MNI.value;
%     XLS(iLead).XLS.hemisphere = XLS(iLead).XLS.hemisphere.value;
% for iMonoPolar = 1:n
%     waitbar(iMonoPolar/n,h)
%     data.leadtype = 'Medtronic3389';
%     data.amplitude = num2str(amplitudes_vector(iMonoPolar));
%     data.voltage = 'False';
%     data.pulsewidth = '60';
%     activevector = [0 0 0 0];
%     activevector(contacts_vector(iMonoPolar)+1) = 1;
%     data.activecontact = strrep(num2str(activevector),'  ',' ');
%     data.groundedcontact = '0 0 0 0';
%    
%     Excel(iLead,iMonoPolar).monoPolarConfig = data;
%     Excel(iLead,iMonoPolar).leadname = XLS(iLead).XLS.leadname.value;
%     Excel(iLead,iMonoPolar).patientname = XLS(iLead).XLS.name.value;
%    
%     monoPolarConfig = data;
%     
%     try
%     thisVTA = predict_loadVTA(monoPolarConfig,handles.config.Cook.VTApoolPath);
%     catch
%         keyboard
%     end
%     
% 
%     [iVTA,rVTA] = predict_getVTAinsweetspotspace(thisVTA,Rsweetspot,XLS(iLead).XLS);
% 
%         if max(iVTA(:)) == 0
%             warning('OUT OF RANGE')
%         end
%         
% 
%         
%         Excel(iLead,iMonoPolar).normalizedVTA.Voxels = single(iVTA>0.5);
%         Excel(iLead,iMonoPolar).normalizedVTA.Imref = rVTA;
% end
%             
            
        end
        
    end
end

