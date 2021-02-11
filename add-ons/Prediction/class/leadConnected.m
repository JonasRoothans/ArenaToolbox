classdef leadConnected<handle
    % All to the lead connected functions go here.
    
    properties
        config
        amplitudesParameter
    end
    
    methods
        function obj = leadConnected()
           %First linking of class to variable
        end
        
        function result = alreadyRun(obj,thisprediction,Patient_Information,leadtype)
            %ALREADYRUN has the power to skip over further calculations if the data is
            %was already computed once before.
            
            currentFolder=cd;
            cd(thisprediction.SavePath);
            result=0;
            if thisprediction.bilateralOn==1
                if strcmp(lower(thisprediction.Tag(end-9:end)),'_bilateral')
                Tag=[thisprediction.Tag(1:end-10),'_Bilateral'];
                else 
                Tag=[thisprediction.Tag,'_Bilateral'];
                end
            else 
                 Tag=thisprediction.Tag;   
            end
            filename=['/',thisprediction.handles.target,'_',...
                leadtype,'_', ...        
                thisprediction.Heatmap.Name,'_',...
                Tag,'_',...
                num2str(Patient_Information.name),'_', ...
                Patient_Information.gender,'_',...
                num2str(Patient_Information.dateOfBirth(1:10)),'_', ...
                num2str(Patient_Information.patientID),'.xls'];
            filename=fullfile(thisprediction.SavePath,filename);
%             if exist(filename,'file')
%                 result=1;
%             end
            cd(currentFolder);
        end
        
        function atlas = getMatchingAtlas(obj,therapyPlanStorage,thisSession,thisprediction,c0)
            %copied from VTAextractor.m of findeTheMatchingAtlas
            % finds the atlas which is given in the datafile
            target=thisprediction.handles.target;
            [~,types] = thisSession.listregisterables;
            numbersOfAtlases = find(contains(types,'Atlas'));
            atlas = [];
            for inumbersOfAtlases = numbersOfAtlases
                thisAtlas = thisSession.getregisterable(inumbersOfAtlases);
                %does the target match?
                if strcmp(lower(thisAtlas.group),lower(target))
                    % is hemisphere matching?
                        if  c0<0 && strcmp(lower(thisAtlas.hemisphere),'left')
                            atlas=thisAtlas;
                            thisprediction.PositionHemisphere.left=1;
                            break
                        elseif  c0>0 && strcmp(lower(thisAtlas.hemisphere),'right')
                            atlas=thisAtlas;
                            thisprediction.PositionHemisphere.right=1;
                            break
                        end
                end
            end
            if isempty(atlas)
                error(['No atlas was found for:', lower(therapyPlanStorage.lead.label),' and ',lower(target),newline,'Please check for mismatched heatmap to data!'])
            end
        end

        function T_atlas_to_legacySpace= findTtolegacySpace(obj,therapyPlanStorage,target)
            %copied from VTAextractor.m of findTtoMNI
            % finds the right Transformation from atlas to legacySpace
            hemispheres = {'left','right'};
            for iHemi = 1:2
                thisHemi = hemispheres{iHemi};
                if contains(lower(therapyPlanStorage.lead.label),...
                        lower(thisHemi))
                    hemisphere = thisHemi;
                    break
                end
            end
            
            T = load('Tapproved.mat');
            atlasname = [lower(hemisphere),lower(target),'2mni'];
            T_atlas_to_legacySpace= T.(atlasname);
        end

        %In this function all possible electrodes and therefor needed settings are
        %created for the Transformation of the VTA themself.
        
        function obj=getConfiguration(obj,thisSession)
        
        valueOfContactLetters=str2num(thisSession.therapyPlanStorage{1,1}.activeRings);
        contacts=numel(valueOfContactLetters);
        contacts = 0:contacts-1;
        amplitudes = obj.amplitudesParameter(1,1):obj.amplitudesParameter(1,2):obj.amplitudesParameter(1,3);
        [contacts2d,amplitudes2d] = meshgrid(contacts,amplitudes); %maybe a new way of getting the same values but without this meshgrid crazyness
        obj.config.contacts_vector = reshape(contacts2d,1,[]);         %gets the 0123 in row to follow in column
        obj.config.amplitudes_vector = reshape(amplitudes2d,1,[]);     %gets the 12345 in row to follow in column
        valueOfContactLetters(valueOfContactLetters~=0)=0;
        obj.config.activevector=valueOfContactLetters;      
        
        end
        
        
        
        function ExporttoVTApool(obj,thisprediction,thisStimplan)
            
            % This function was more or less the same in a old Predict.m toolbox to
            % find. You can still find it in this Version of the toolbox but it will be
            % deleted in the future, if the idea behinde is also not needed anymore.
            
            
            type = thisStimplan{1}.lead.leadType;
            amp = num2str(round(thisStimplan{1}.stimulationValue,1));
            voltagecontrolled = thisStimplan{1}.voltageBasedStimulation;
            pw = num2str(thisStimplan{1}.pulseWidth);
            cathode = ['c',thisStimplan{1}.activeRings];
            anode = ['a',thisStimplan{1}.contactsGrounded];
            name = [type,amp,voltagecontrolled,pw,cathode,anode,'.mat'];
            
            %Rvta: dim, spacing
            Rvta = imref3d(thisStimplan{1}.vta.Medium.volumeInfo.dimensions,...
                thisStimplan{1}.vta.Medium.volumeInfo.spacing(1),...
                thisStimplan{1}.vta.Medium.volumeInfo.spacing(2),...
                thisStimplan{1}.vta.Medium.volumeInfo.spacing(3));
            %Rvta: origin
            Rvta.XWorldLimits = Rvta.XWorldLimits+thisStimplan{1}.vta.Medium.volumeInfo.origin(1);
            Rvta.YWorldLimits = Rvta.YWorldLimits+thisStimplan{1}.vta.Medium.volumeInfo.origin(2);
            Rvta.ZWorldLimits = Rvta.ZWorldLimits+thisStimplan{1}.vta.Medium.volumeInfo.origin(3);
            
            Ivta = thisStimplan{1}.vta.Medium.voxelArray;
            
            if ~exist(fullfile(thisprediction.VTAPoolPath,name),'file')
                save(fullfile(thisprediction.VTAPoolPath,name),'Rvta','Ivta');
            end
            
            if isempty(thisprediction.config.FirstLeadrelatedVTA.name) && thisprediction.PositionHemisphere.left
                thisprediction.config.FirstLeadrelatedVTA.name=name;
                thisprediction.config.FirstLeadrelatedVTA.VTA=[];
            else thisprediction.PositionHemisphere.right
                thisprediction.config.SecondLeadrelatedVTA=[];
                thisprediction.config.SecondLeadrelatedVTA.name=name;
            end
        end
        
        function [Ivta,Rvta] = getVTAInformation(obj,thisStimplan)
            %This Function collects the Image References and Image Pixel Data.
            %Rvta: dim, spacing
            Rvta = imref3d(thisStimplan.vta.Medium.volumeInfo.dimensions,...
                thisStimplan.vta.Medium.volumeInfo.spacing(1),...
                thisStimplan.vta.Medium.volumeInfo.spacing(2),...
                thisStimplan.vta.Medium.volumeInfo.spacing(3));
            %Rvta: origin
            Rvta.XWorldLimits = Rvta.XWorldLimits+thisStimplan.vta.Medium.volumeInfo.origin(1);
            Rvta.YWorldLimits = Rvta.YWorldLimits+thisStimplan.vta.Medium.volumeInfo.origin(2);
            Rvta.ZWorldLimits = Rvta.ZWorldLimits+thisStimplan.vta.Medium.volumeInfo.origin(3);
            
            Ivta = thisStimplan.vta.Medium.voxelArray;
        end
        
        function VTA = loadVTA(obj,data,thisprediction)
            if isa(data,'struct')
            name = [data.leadtype,...
                num2str(data.amplitude),...
                num2str(data.voltage),...
                num2str(data.pulsewidth),...
                'c',data.activecontact,...
                'a',data.groundedcontact,...
                '.mat'];
            else
                name=data;
            end
            VTA = load(fullfile(thisprediction.VTAPoolPath,name));
            
        end
        
        function [Ipsmleft,Rpsmleft]=  getVTAInMNISpace(obj,VTA,thisprediction,TransformationLegacySpace,hemisphere)
            
            %this code originally comes from Predict.m toolbox but was eddited on all
            %major parts
            
            T = load('Tapproved.mat');
            Ivta = VTA.Ivta;
            Rvta = VTA.Rvta;
            Rvta.XWorldLimits = [-7.5 7.5];
            Rvta.YWorldLimits = [-7.5 7.5];
            Tlegacy2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
            
             
            hemispheres = {'left','right'};
            mirror2hemisphere = [1,0];
            
            Ipsmleft = nan;
            Rpsmleft = nan;
            
            for iHemisphere = 1:2
                thisHemisphere = hemispheres{iHemisphere};
                otherHemisphere = hemispheres{3-iHemisphere};
                %only continue if destination hemisphere is matching, so:
                %If only 1 mirror --> only 1 output.
                %   Is mirror not set to iHemisphere? --> continue
                %Elseif No mirrror --> 2 outputs possible.
                %   Is hemisphere not matching? --> continue
                %When both mirrorings are turned on --> they are identical.
                
                switch thisprediction.Heatmap.Name
                    case 'DystoniaWuerzburg'
                    if sum(mirror2hemisphere)==1 && ~mirror2hemisphere(iHemisphere)
                        continue
                    end
                    Rpsm = thisprediction.Heatmap.T_Data.R;
                    Ipsm = zeros(size(thisprediction.Heatmap.T_Data.Voxels));
                    % The VTa gets mirrored when the sides doesn't match each other. Also it gets transformed from its own space to the Legacy Space.
                    if  ~strcmp(lower(hemisphere),lower(hemispheres{iHemisphere})) % mirror
                        Tvta = affine3d(round((TransformationLegacySpace* T.(['mni2',otherHemisphere,'gpi'])*T.([thisHemisphere,'gpi2mni'])*Tlegacy2mni),8));
                    else %No need to mirror.
                        Tvta = affine3d(round((TransformationLegacySpace*Tlegacy2mni),8));             % search for better way of putting the transformation matrix at first in data.Tlead2MNI
                    end
                    case 'heatmapBostonBerlin'
                        Rpsm = thisprediction.Heatmap.Data.R;
                        Ipsm = zeros(size(thisprediction.Heatmap.Data.Voxels));           %groundmap of the original size of the picture
                        Tvta = affine3d(round((TransformationLegacySpace*Tlegacy2mni),8));
                    case 'heatmapBostonAlone'
                        Rpsm = thisprediction.Heatmap.Data.R;
                        Ipsm = zeros(size(thisprediction.Heatmap.Data.Voxels));           %groundmap of the original size of the picture
                        Tvta = affine3d(round((TransformationLegacySpace*Tlegacy2mni),8));
                end
                %% transform the VTA to MNI
                [Iwarp,Rwarp] = imwarp(Ivta,Rvta,Tvta);
                %make a meshgrid of reference of Legacyspace in specific dimensions
                [xq,yq,zq] = imref2meshgrid(Rpsm);
                %make a meshgrid of input
                [x,y,z] = imref2meshgrid(Rwarp);            %is only to overlay both
                
                %Resample
                Ipsm = interp3(x,y,z,Iwarp,xq,yq,zq);       % the input data doesn't perfectly fit with the original data samples,
                %thats why it needs to be interpolated
                disp('Transformation, Mirroring and Interpolation done!');
                %delete Nans
                Ipsm(isnan(Ipsm)) = 0;
                
                if strcmp(lower(thisHemisphere),'left')
                        Ipsmleft = Ipsm;
                        Rpsmleft = Rpsm;
                end
                
            end
        end
        
        function getMissingMetaData(obj,thisSession,thisprediction)
            for fselect=1:numel(thisSession.therapyPlanStorage)
                if thisprediction.bilateralOn
                    for sselect=1:numel(thisSession.therapyPlanStorage)
                        selected=thisSession.therapyPlanStorage{1,fselect}.lead.distal(1,1)>0;
                        maybeMatching=thisSession.therapyPlanStorage{1,sselect}.lead.distal(1,1)>0;
                        if selected~=maybeMatching
                            message=['Two electrodes of one Session for left and right were found!',...
                                newline, 'Do you want to run a bilateral prediction for',newline,' %s and %s?'];
                            message=sprintf(message,thisSession.therapyPlanStorage{1,fselect}.lead.label,thisSession.therapyPlanStorage{1,sselect}.lead.label);
                            answer=questdlg(message,'Bilateral?','Yes','No','Yes');
                            if strcmp(answer,'Yes')
                                thisprediction.bilateralOn=1;
                                thisprediction.config.FirstLead.NumberOfLead=fselect;
                                answer=questdlg('Where was the first lead implanted?','Task','Left','Right','Left');
                                if strcmp(answer,'Left')
                                    thisprediction.config.FirstLead.c0=-10; %this needs to be smaller than 0, that is the expression for left
                                elseif strcmp(answer,'Right')
                                    thisprediction.config.FirstLead.c0=10;
                                end
                                thisprediction.config.SecondLead.NumberOfLead=sselect;
                                thisprediction.config.SecondLead.C0 = thisSession.therapyPlanStorage{1,sselect}.lead.distal(1,1);
                                answer=questdlg('Where was the second lead implanted?','Task','Left','Right','Right');
                                if strcmp(answer,'Left')
                                    thisprediction.config.SecondLead.c0=-10; %this needs to be smaller than 0, that is the expression for left
                                elseif strcmp(answer,'Right')
                                    thisprediction.config.SecondLead.c0=10;
                                end
                                waitfor(msgbox('Your bilateral prediction data will be stored in the Actor you just selected...'));
                                obj.config.runWithoutLoadedActor=1;
                                return;
                            end
                        end
                    end
                else
                    message='Do you want a unilateral prediction with %s';
                    message=sprintf(message,thisSession.therapyPlanStorage{1,fselect}.lead.label);
                    answer=questdlg(message,'Unilateral','Yes','No','Yes');
                    if strcmp(answer,'Yes')
                    thisprediction.config.FirstLead.NumberOfLead=fselect;
                    answer=questdlg('Where was your lead implanted?','Task','Left','Right','Left');
                    if strcmp(answer,'Left')
                    thisprediction.config.FirstLead.c0=-10; %this needs to be smaller than 0, that is the expression for left    
                    elseif strcmp(answer,'Right')
                    thisprediction.config.FirstLead.c0=10;    
                    end
                    obj.config.runWithoutLoadedActor=1;
                    return;
                    end
                end
            end  
            if isempty(thisprediction.config)
                error('You have to select a lead!');
            end
        end 
    end
end

