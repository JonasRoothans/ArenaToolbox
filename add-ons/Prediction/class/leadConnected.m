classdef leadConnected<handle
    % To provide the buttomConnected class with all data pieces it needs
    % for calculations and so on, this class was created.
    
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
                try
                    if strcmp(lower(thisprediction.Tag(end-9:end)),'_bilateral')
                        Tag=[thisprediction.Tag(1:end-10),'_Bilateral'];
                    else
                        Tag=[thisprediction.Tag,'_Bilateral'];
                    end
                catch
                    Tag=thisprediction.Tag;
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
            %             cd(currentFolder);
        end
        
        function atlas = getMatchingAtlas(obj,therapyPlanStorage,thisSession,thisprediction,C0)
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
                    if  C0<0 && strcmp(lower(thisAtlas.hemisphere),'left')
                        atlas=thisAtlas;
                        thisprediction.PositionHemisphere.left=1;
                        break
                    elseif  C0>0 && strcmp(lower(thisAtlas.hemisphere),'right')
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
        
        function obj=getConfiguration(obj,thisSession)
            %In this function all possible electrodes and therefor needed settings are
            %created for the Transformation of the VTA themself.
            valueOfContactLetters=str2num(thisSession.therapyPlanStorage{1,1}.activeRings);
            contacts=numel(valueOfContactLetters);
            contacts = 0:contacts-1;
            amplitudes = obj.amplitudesParameter(1,1):obj.amplitudesParameter(1,2):obj.amplitudesParameter(1,3);
            [contacts2d,amplitudes2d] = meshgrid(contacts,amplitudes); %maybe a new way of getting the same values but without this meshgrid crazyness
            obj.config.contacts_vector = reshape(contacts2d,1,[]);         %gets numbers in row to follow in column
            obj.config.amplitudes_vector = reshape(amplitudes2d,1,[]);     %gets numbers in row to follow in column
            valueOfContactLetters(valueOfContactLetters~=0)=0;
            obj.config.activevector=valueOfContactLetters;
            
        end
        
        
        
        function ExporttoVTApool(obj,thisprediction,thisStimplan)
            
            % This function was more or less the same in a old Predict.m toolbox to
            % find.
            
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
            %This function collects the Image References and Image Pixel Data.
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
            % The VTA chosen through the specifications in buttomConnected
            % is searched and loaded.
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
                
                switch thisprediction.Heatmap.Name
                    case 'DystoniaWuerzburg'
                        if sum(mirror2hemisphere)==1 && ~mirror2hemisphere(iHemisphere)
                            continue
                        end
                        Rpsm = thisprediction.Heatmap.T_Data.R;
                        Ipsm = zeros(size(thisprediction.Heatmap.T_Data.Voxels));
                        % The VTA gets mirrored when the sides doesn't match each other. Also it gets transformed from its own space to the Legacy Space.
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
            %When a prediction is run without preloaded data you need this
            %function to determine on what leads you want to do your
            %prediction. The question for which side the lead is placed
            %should be changed to an automatic procedure in later versions.
            window1=figure;
            selectButton=uicontrol('style','togglebutton','parent',window1,'units','normalized','position',...
                [0.01 0.01 0.99 0.1],'string','Confirm');
            if thisprediction.bilateralOn
                maxBiggerZero=0;
                maxSmallerZero=0;
                tic
                for n=1:numel(thisSession.therapyPlanStorage)
                    if  thisSession.therapyPlanStorage{1,n}.lead.distal(1,1)<0
                        maxSmallerZero=maxSmallerZero+1;
                        time1=toc;
                    elseif thisSession.therapyPlanStorage{1,n}.lead.distal(1,1)>0
                        maxBiggerZero=maxBiggerZero+1;
                        time2=toc;
                    end
                end
                if time2>time1
                    maxBiggerZero=maxBiggerZero+maxSmallerZero;
                elseif time1>time2
                    maxSmallerZero=maxSmallerZero+maxBiggerZero;
                end
                
                if numel(thisSession.therapyPlanStorage)==maxBiggerZero
                    lowerLimitLeftBox=maxSmallerZero+1;
                    upperLimitLeftBox=maxBiggerZero;
                    lowerLimitRightBox=1;
                    upperLimitRightBox=maxSmallerZero;
                elseif numel(thisSession.therapyPlanStorage)==maxSmallerZero
                    lowerLimitLeftBox=1;
                    upperLimitLeftBox=maxBiggerZero;
                    lowerLimitRightBox=maxBiggerZero+1;
                    upperLimitRightBox=maxSmallerZero;
                end
                counter=0;
                optionsLeftBox={};
                optionsRightBox={};
                for n=lowerLimitLeftBox:upperLimitLeftBox
                    counter=counter+1;
                    optionsLeftBox{counter}=[thisSession.therapyPlanStorage{1,n}.lead.label,'for StimPlan',num2str(n)];
                end
                counter=0;
                for n=lowerLimitRightBox:upperLimitRightBox
                    counter=counter+1;
                    optionsRightBox{counter}=[thisSession.therapyPlanStorage{1,n}.lead.label,'for StimPlan',num2str(n)];
                end
                leftBox=uicontrol('parent',window1,'units','normalized','position',...
                    [0.05 0.2 0.4 0.7],'style','listbox','string',optionsLeftBox);
                rightBox=uicontrol('parent',window1,'units','normalized','position',...
                    [0.57 0.2 0.4 0.7],'style','listbox','string',optionsRightBox);
                
                waitfor(selectButton,'Value',1);
                if numel(thisSession.therapyPlanStorage)==maxBiggerZero
                    thisprediction.config.FirstLead.NumberOfLead=maxSmallerZero+leftBox.Value;
                    thisprediction.config.SecondLead.NumberOfLead=rightBox.Value;
                elseif numel(thisSession.therapyPlanStorage)==maxSmallerZero
                    thisprediction.config.FirstLead.NumberOfLead=leftBox.Value;
                    thisprediction.config.SecondLead.NumberOfLead=maxBiggerZero+rightBox.Value;
                end
                
                thisprediction.config.FirstLead.C0=[];
                thisprediction.config.FirstLead.C0.x=-10; %this needs to be smaller than 0, that is the expression for left
                %                                 thisprediction.config.SecondLead.C0 = thisSession.therapyPlanStorage{1,maxSmallerZero}.lead.distal(1,1);
                thisprediction.config.SecondLead.C0=[];
                thisprediction.config.SecondLead.C0.x=10;
                waitfor(msgbox('Your bilateral prediction data will be stored in the Actor you just selected...'));
                obj.config.runWithoutLoadedActor=1;
                delete(window1);
                return;
            else
                counter=0;
                options={};
                for n=1:numel(thisSession.therapyPlanStorage)
                    counter=counter+1;
                    options{counter}=[thisSession.therapyPlanStorage{1,n}.lead.label,'for StimPlan',num2str(n)];
                end
                box=uicontrol('parent',window1,'units','normalized','position',...
                    [0.01 0.2 0.4 0.7],'style','listbox','string',options);
                waitfor(selectButton,'Value',1);
                if  thisSession.therapyPlanStorage{1,box.Value}.lead.distal(1,1)<0
                    thisprediction.config.FirstLead.C0.x=10;
                elseif thisSession.therapyPlanStorage{1,box.Value}.lead.distal(1,1)>0
                    thisprediction.config.FirstLead.C0.x=-10;
                end
                thisprediction.config.FirstLead.NumberOfLead=box.Value;
                obj.config.runWithoutLoadedActor=1;
                delete(window1);
                return;
            end
            
        end
    end
end

