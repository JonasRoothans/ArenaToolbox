classdef leadConnected<handle
    % All to the lead connected functions go here.
    
    properties
        config
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
            filename=['/',thisprediction.handles.target,'_',...
                leadtype,'_', ...        
                thisprediction.Heatmap.Name,'_',...
                thisprediction.Tag,'_',...
                num2str(Patient_Information.name),'_', ...
                Patient_Information.gender,'_',...
                num2str(Patient_Information.dateOfBirth(1:10)),'_', ...
                num2str(Patient_Information.patientID),'.mat'];
            filename=fullfile(thisprediction.SavePath,filename);
            if exist(filename,'file')
                result=1;
            end
            cd(currentFolder);
        end
        
        function atlas = getMatchingAtlas(obj,therapyPlanStorage,thisSession,target)
            %copied from VTAextractor.m of findeTheMatchingAtlas
            % finds the atlas which is given in the datafile
            [~,types] = thisSession.listregisterables;
            numbersOfAtlases = find(contains(types,'Atlas'));
            atlas = [];
            for inumbersOfAtlases = numbersOfAtlases
                thisAtlas = thisSession.getregisterable(inumbersOfAtlases);
                %does the target match?
                if strcmp(lower(thisAtlas.group),lower(target))
                    % is hemisphere matching?
                    if contains(lower(therapyPlanStorage.lead.label),...
                            lower(thisAtlas.hemisphere))                            %depending on what the person entered to the label, you need to adjust
                        atlas = thisAtlas;
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
        
        valueOfContactLetters=str2num(thisSession.therapyPlanStorage{1, 1}.activeRings);
        contacts=numel(valueOfContactLetters);
        contacts = 0:contacts-1;
        amplitudes = 1:5;
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
            
            
            type = thisStimplan.lead.leadType;
            amp = num2str(round(thisStimplan.stimulationValue,1));
            voltagecontrolled = thisStimplan.voltageBasedStimulation;
            pw = num2str(thisStimplan.pulseWidth);
            cathode = ['c',thisStimplan.activeRings];
            anode = ['a',thisStimplan.contactsGrounded];
            name = [type,amp,voltagecontrolled,pw,cathode,anode,'.mat'];
            
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
            
            if ~exist(fullfile(thisprediction.VTAPoolPath,name),'file')
                save(fullfile(thisprediction.VTAPoolPath,name),'Rvta','Ivta');
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
        
        function VTA = loadVTA(obj,data,VTApool)
            name = [data.leadtype,...
                num2str(data.amplitude),...
                num2str(data.voltage),...
                num2str(data.pulsewidth),...
                'c',data.activecontact,...
                'a',data.groundedcontact,...
                '.mat'];
            
            VTA = load(fullfile(VTApool,name));
            
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
    end
end

