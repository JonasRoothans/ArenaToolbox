classdef buttonConnected<handle
    % All to the button connected functions go here.
    
    properties
        progress
    end
    
    methods
        function [Excel_output,Patient_Information,result]=VTA_Transformation(obj,thisprediction,waitbarFigurePredictFuture)
            %--
            %to work on this data, we need the toolbox Suretune SDK and
            %it's own class
            
            thisSession=Session;
            thisSession.developerFlags.readable = 0; %this value needs to be cleared, that you can work on the data
            thisSession.loadsession(thisprediction.Data_In);
            [~,Rtype] = thisSession.listregisterables;
            leadidcs = find(contains(Rtype,'Lead'));
            if isempty(thisSession.therapyPlanStorage)
                error('No patient therapy plan found!')
            end
            
            obj.progress.Value=0.13;
            
            lead=leadConnected();
            
            % store the patient information for later saving
            Patient_Information=thisSession.patient;
            
            %get all configuration data, which is only asked for in the
            %first run
            if not(exist('predictionConfig.mat','file'))
                waitfor(msgbox('This seems to be your first time running the Prediction Algorythm? Please choose your VTA path!'));
                thisprediction.VTAPoolPath=uigetdir;
                predictionConfig.VTAPoolPath=thisprediction.VTAPoolPath;
                waitfor(msgbox(' and a path where you want to save all predictions!'));
                thisprediction.SavePath=uigetdir;
                predictionConfig.SavePath=thisprediction.SavePath;
                if not(any(thisprediction.SavePath)) || not(any(thisprediction.VTAPoolPath))
                    error('You need to select a directory for saving and the pool path!');
                end
                folder=what('Prediction');
                mkdir ../Prediction Temp
                predictionConfig.Temp=[folder.path,'/Temp'];
                thisprediction.Temp=[folder.path,'/Temp'];
                addpath('Temp');
                save(fullfile(folder.path,'/predictionConfig'),'predictionConfig');
            else
                config=load('predictionConfig.mat');
                thisprediction.VTAPoolPath=config.predictionConfig.VTAPoolPath;
                thisprediction.SavePath=config.predictionConfig.SavePath;
                thisprediction.Temp=config.predictionConfig.Temp;
            end
            
            obj.progress.Value=0.14;
            
            %check if this Prediction was already done
            result=lead.alreadyRun(thisprediction,Patient_Information,thisSession.therapyPlanStorage{1, 1}.lead.leadType);
            if result==1
                answer=questdlg('You already did this computation once! Do you want to do it again?','Checking','YES','NO','NO');
                if strcmp(answer,'YES')
                    result=0;
                end
                Excel_output=0;
            end
            if result==0
                
                % If you want a prediction on data not shown in Arena, you
                % need this!
                if isempty(thisprediction.config)
                    lead.getMissingMetaData(thisSession,thisprediction);
                end
                
                % Check wheter first is left, how it has to be...
                if thisprediction.config.FirstLead.c0(1,1)>0
                    firstLead=thisprediction.config.FirstLead;
                    thisprediction.config.FirstLead=[];
                    thisprediction.config.FirstLead.maxStimPlans=[];
                    try
                        SecondLead=thisprediction.config.SecondLead;
                        thisprediction.config.FirstLead=SecondLead;
                    catch
                        warning('No second lead found! It is okay for unilateral predictions.');
                        % In first lead there needs to be a maxStimPlan number,
                        % because it is used later on. If the leads have
                        % different amount of stimPlans you get the other on.
                        try
                            runOld=lead.config.runWithoutLoadedActor;
                        catch
                            for itherapyPlans=1:numel(thisSession.therapyPlanStorage)
                                if firstLead.maxStimPlans~=numel(thisSession.therapyPlanStorage{1, itherapyPlans}.lead.stimPlan)
                                    thisprediction.config.FirstLead.maxStimPlans=numel(thisSession.therapyPlanStorage{1, itherapyPlans}.lead.stimPlan);
                                    break;
                                end
                            end
                            if isempty(thisprediction.config.FirstLead.maxStimPlans)
                                thisprediction.config.FirstLead.maxStimPlans=firstLead.maxStimPlans;
                            end
                        end
                    end
                    thisprediction.config.SecondLead=firstLead;
                end
                
                obj.progress.Value=0.15;
                
                %Check whether it was done with an Actor or with selected
                %Data inside the predictFuture enviroment.
                
                try
                    runOld=lead.config.runWithoutLoadedActor;
                catch
                    %change of Actor Name to a better understandable one
                    if thisprediction.bilateralOn==1
                        if strcmp(lower(thisprediction.Tag(end-9:end)),'_bilateral')
                        else
                            thisprediction.Tag=[ thisprediction.Tag,'_Bilateral'];
                        end
                    elseif strcmp(lower(thisprediction.Tag(end-9:end)),'_bilateral')
                        thisprediction.Tag=thisprediction.Tag(1:end-10);
                    end
                    try
                        thisprediction.config.SecondLead.NumberOfLead=thisprediction.config.FirstLead.maxStimPlans+thisprediction.config.SecondLead.NumberOfLead;
                    catch
                        warning('No second lead found! It is okay for unilateral predictions.');
                    end
                end
                
                % Finding of Transformation data
                thisprediction.PositionHemisphere.left=0;
                thisprediction.PositionHemisphere.right=0;
                for itherapyPlanNumber=1:2
                    try
                        c0=thisprediction.config.FirstLead.c0; % If you run this and you only have a right lead...
                    catch
                        itherapyPlanNumber=2;
                    end
                    if itherapyPlanNumber==1                    % You need always the right number of the stimplan. But in thisSession all therapyPlans are more or less all stimplans there where found in on column.
                        PlanNumber=thisprediction.config.FirstLead.NumberOfLead;
                        try
                            c0=thisprediction.config.FirstLead.c0(1,1);
                        catch
                        end
                    elseif itherapyPlanNumber==2
                        try
                            PlanNumber=thisprediction.config.SecondLead.NumberOfLead;
                            c0=thisprediction.config.SecondLead.c0(1,1);
                        catch
                            continue;
                        end
                    end
                    loop_therapyPlanStorage=thisSession.therapyPlanStorage{PlanNumber};
                    loop_atlas=lead.getMatchingAtlas(loop_therapyPlanStorage,thisSession,thisprediction,c0);
                    atlas{itherapyPlanNumber}=loop_atlas;
                    %Transformation from electrode space to selected atlas
                    %space
                    T_vta_to_atlas = thisSession.gettransformfromto(loop_therapyPlanStorage.lead,loop_atlas);
                    T_atlas_to_legacySpace= lead.findTtolegacySpace(loop_therapyPlanStorage,thisprediction.handles.target);
                    thisprediction.handles.TransformationLegacySpace{itherapyPlanNumber} =...            % this is the euqivalent of XLS.Tlead2MNI.value
                        T_vta_to_atlas*T_atlas_to_legacySpace;          %If this value of correctness is not needed it can be shortened with round()
                end
                
                obj.progress.Value=0.17;
                
                % VTA with Information is created
                status='%d. Lead and %d. Contactcombination for aligning monopolar VTAs to sweetspot...';
                
                Excel_output=[];
                
                %for now on you can work with Boston or Medtronic leads and its
                %configuration data
                
                lead.amplitudesParameter=thisprediction.amplitudesParameter;
                lead.getConfiguration(thisSession);
                thisprediction.config.FirstLeadrelatedVTA=[];%otherwise the could will not work with an if statement
                thisprediction.config.FirstLeadrelatedVTA.name=[];
                thisprediction.config.FirstLeadrelatedVTA.VTA=[];
                thisprediction.configStructure=lead.config;
                switch thisprediction.Heatmap.Name
                    case 'DystoniaWuerzburg'
                        %Please never switch reslicing on with the Dystonia Heatmap
                        %This would change your prediction severe!!!
                        % You switch it on without the 1 as the second
                        % index!
                        thisprediction.Heatmap.T_Data=VoxelData;
                        thisprediction.Heatmap.P_Data=VoxelData;
                        thisprediction.Heatmap.T_Data.loadnii('BilateralSweetspot_t_p_average_realMNI_nii_tValue.nii',1);
                        thisprediction.Heatmap.P_Data.loadnii('BilateralSweetspot_t_p_average_realMNI_nii_pValue.nii',1);
                    case 'heatmapBostonBerlin'
                        %Please never switch reslicing off with the
                        %BostonBerlin Heatmap!
                        % This would destroy your result, because the
                        % original data lives in the wrong space!
                        thisprediction.Heatmap.Data=VoxelData;
                        thisprediction.Heatmap.Data.loadnii('BER_MDST_UPDRS_corrdata_exch_palm_vox_vstat_R_Fz_yeo1000_dil_map.nii');
                    case 'heatmapBostonAlone'
                        %Please never switch reslicing off with the
                        %BostonAlone Heatmap!
                        % This would destroy your result, because the
                        % original data lives in the wrong space!
                        thisprediction.Heatmap.Data=VoxelData;
                        thisprediction.Heatmap.Data.loadnii('cogdec_SE_vs_noSE_orig_fz_use_design_palm_vox_tstat_yeo1000_dil_precomputed_corr_R_Fz.nii');
                    otherwise
                        disp('You did not select a Heatmap which can be used!');
                end
                
                %For prove of this, just look in the programm folder for
                %ProoveOfWrongSpace
                iLead=0;
                while iLead~=2
                    iLead=iLead+1;
                    try
                        c0=thisprediction.config.FirstLead.c0; % If you run this and you only have a right lead...
                    catch
                        iLead=2;
                    end
                    if iLead==1                    % You need always the right number of the stimplan. But in thisSession all therapyPlans are more or less all stimplans there where found in on column.
                        PlanNumber=thisprediction.config.FirstLead.NumberOfLead;
                        
                    elseif iLead==2
                        try
                            PlanNumber=thisprediction.config.SecondLead.NumberOfLead;
                            
                            obj.progress.Value=0.26;
                            
                        catch
                            break;
                        end
                    end
                    % This stores the vta which is coming within the
                    % dataset, which was loaded.
                    thisLead = thisSession.therapyPlanStorage(PlanNumber);
                    lead.ExporttoVTApool(thisprediction,thisLead);
                    if isempty(thisprediction.config.FirstLeadrelatedVTA.VTA) && thisprediction.PositionHemisphere.left
                    thisprediction.config.FirstLeadrelatedVTA.VTA = lead.loadVTA(thisprediction.config.FirstLeadrelatedVTA.name,thisprediction);
                    [thisprediction.config.FirstLeadrelatedVTA.iVTA,thisprediction.config.FirstLeadrelatedVTA.rVTA] = lead.getVTAInMNISpace(thisprediction.config.FirstLeadrelatedVTA.VTA,thisprediction,...
                            thisprediction.handles.TransformationLegacySpace{1,iLead},atlas{1,iLead}.hemisphere);
                    else
                    thisprediction.config.SecondLeadrelatedVTA.VTA = lead.loadVTA(thisprediction.config.SecondLeadrelatedVTA.name,thisprediction);
                    [thisprediction.config.SecondLeadrelatedVTA.iVTA,thisprediction.config.SecondLeadrelatedVTA.rVTA] = lead.getVTAInMNISpace(thisprediction.config.SecondLeadrelatedVTA.VTA,thisprediction,...
                            thisprediction.handles.TransformationLegacySpace{1,iLead},atlas{1,iLead}.hemisphere);
                    end
                    for iMonoPolar = 1:numel(lead.config.amplitudes_vector)
                        disp(fprintf(status,iLead,iMonoPolar));
                        data.pulsewidth='150';       %Big question, is it enough or more correctness needed?
                        data.voltage='False';
                        data.leadtype='Medtronic3389';
                        data.groundedcontact='0 0 0 0';
                        
                        obj.progress.Value=obj.progress.Value+numel(lead.config.amplitudes_vector)/(numel(lead.config.amplitudes_vector)*10000);
                        
                        %                         data.leadtype= thisSession.therapyPlanStorage{1, PlanNumber}.lead.leadType; %this is like how it should be with a bigger vta pool
                        %                         data.voltage = thisSession.therapyPlanStorage{1, PlanNumber}.voltageBasedStimulation;
                        %                         data.pulsewidth = thisSession.therapyPlanStorage{1, PlanNumber}.pulseWidth;
                        %                         data.groundedcontact = thisSession.therapyPlanStorage{1, PlanNumber}.contactsGrounded;
                        
                        data.amplitude = num2str(lead.config.amplitudes_vector(iMonoPolar));
                        activevector = lead.config.activevector;
                        activevector(lead.config.contacts_vector(iMonoPolar)+1) = 1;
                        data.activecontact = strrep(num2str(activevector),'  ',' ');
                        
                        Excel_output(iLead,iMonoPolar).monoPolarConfig = data;
                        Excel_output(iLead,iMonoPolar).leadname = thisSession.therapyPlanStorage{1,PlanNumber}.lead.label;
                        
                        try
                            thisVTA = lead.loadVTA(data,thisprediction); %loads what was created with the makerecipeCodeMac
                        catch
                            error(['No matching VTA was found in the VTA Pool Path!', 'Please make sure you have all possibilities as VTAs!',newline,...
                                'If you do not understand what is the issue here, please ask Tim!']);
                        end
                        
                        [iVTA,rVTA] = lead.getVTAInMNISpace(thisVTA,thisprediction,...
                            thisprediction.handles.TransformationLegacySpace{1,iLead},atlas{1,iLead}.hemisphere);
                        
                        if max(iVTA(:)) == 0
                            warning('OUT OF RANGE')
                        end
                        
                        Excel_output(iLead,iMonoPolar).normalizedVTA.Voxels = single(iVTA>0.5);    %voxels as only greater than 0.5 of all iVTA data
                        Excel_output(iLead,iMonoPolar).normalizedVTA.Imref = rVTA;
                        
                    end
                    try
                        if isempty(thisprediction.config.SecondLead)
                            iLead=2;
                        end
                    catch
                    end
                end
            end
        end
        
        function [bilateral,unilateral]=predictionProcess(obj,thisprediction)
            %this is essentially the old existing function from predict_ApplyGPiPredictionModel but with some
            %edditings
            
            edges = -1:0.13333333333:1;                                 % gives the area of the histogram
            bilateral=[];
            unilateral=[];
            unilateral.left=[];
            unilateral.right=[];
            
            switch thisprediction.Heatmap.Name
                case 'DystoniaWuerzburg'
                    linearRegressionCoefficients = [57.6598809951595;12.0664757620877;15.6438035692808;...
                        4.57530292424259;-3.13275389368958;-14.8795376587032;...
                        -14.5891044360106;0;16.9708673876284;12.6398172008286;...
                        8.23591228720219;13.9285582004609;4.62858440753228;...
                        -25.9956758412821;17.0527413996103;8.60861313752535];   % this are the coefficients for the linear regression model
                    
                    heatmap.tmap = thisprediction.Heatmap.T_Data.Voxels;
                    heatmap.pmap = thisprediction.Heatmap.P_Data.Voxels;
                    signed_p_map = (1-heatmap.pmap).*sign(heatmap.tmap);
                    
                    % T makes statement to amount of difference between groups and p says how
                    % likely it ist that those groups are similar.
                    % That means a low p value is good and says that you have really some different
                    % groups. In this case you combine it with the t value and get a statement
                    % about how more positiv the different voxels are or how more negativ one of both
                    % compared voxels is.
                    thisprediction.confidenceLevel=confidenceLevel();
                    thisprediction.confidenceLevel.side=thisprediction.PositionHemisphere;
                    
                    
                    if thisprediction.PositionHemisphere.left==1
                        status='%d. left Lead predicted';
                        fig1=figure('Name','Monopolar_Histogramm-Left');
                        % it is always bilateral
                        unilateral.left = [];
                        thisprediction.confidenceLevel.sampleToRealMNI(thisprediction.Heatmap,size(thisprediction.handles.VTA_Information,2));
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            disp(fprintf(status,fXLS));
                            sample = signed_p_map(and(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5,heatmap.pmap>0));
                            thisprediction.confidenceLevel.calculationConfidenceLevel(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels,fXLS);
                            % When you take only values which aren't 0 than you get only a worsening or
                            % improving effekt for the prediction.
                            
                            h = histogram(sample,edges);
                            distanceFromMeanOfMostLikelyEffekt = [1,zscore(h.Values)];   % normaly just the signed_p_map would be enough, but big VTAs would get a hugh weight in the prediction
                            unilateral.left(fXLS) = distanceFromMeanOfMostLikelyEffekt*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                        end
                        sample = signed_p_map(and(thisprediction.config.FirstLeadrelatedVTA.iVTA>0.5,heatmap.pmap>0));
                        h = histogram(sample,edges);
                        distanceFromMeanOfMostLikelyEffekt = [1,zscore(h.Values)];
                        unilateral.leftVTAPrediction=distanceFromMeanOfMostLikelyEffekt*linearRegressionCoefficients;
                        delete(fig1)
                    end
                    
                    if thisprediction.PositionHemisphere.right==1
                        status='%d. right Lead predicted';
                        fig2=figure('Name','Monopolar_Histogramm-Right');
                        % it is always bilateral
                        unilateral.right = [];
                        thisprediction.confidenceLevel.sampleToRealMNI(thisprediction.Heatmap,size(thisprediction.handles.VTA_Information,2));
                        for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            disp(fprintf(status,sXLS));
                            sample = signed_p_map(and(thisprediction.handles.VTA_Information(2,sXLS).normalizedVTA.Voxels>0.5,heatmap.pmap>0));
                            thisprediction.confidenceLevel.calculationConfidenceLevel(thisprediction.handles.VTA_Information(2,sXLS).normalizedVTA.Voxels,sXLS);
                            % When you take only values which aren't 0 than you get only a worsening or
                            % improving effekt for the prediction.
                            
                            h = histogram(sample,edges);
                            distanceFromMeanOfMostLikelyEffekt = [1,zscore(h.Values)];   % normaly just the signed_p_map would be enough, but big VTAs would get a hugh weight in the prediction
                            unilateral.right(sXLS) = distanceFromMeanOfMostLikelyEffekt*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                        end
                        sample = signed_p_map(and(thisprediction.config.SecondLeadrelatedVTA.iVTA>0.5,heatmap.pmap>0));
                        h = histogram(sample,edges);
                        distanceFromMeanOfMostLikelyEffekt = [1,zscore(h.Values)];
                        unilateral.rightVTAPrediction=distanceFromMeanOfMostLikelyEffekt*linearRegressionCoefficients;
                        delete(fig2)
                    end
                    
                    if thisprediction.bilateralOn==1
                        status='%d. left Lead and %d. right Lead predicted';
                        fig3=figure('Name','Bilateral_Histogramm');
                        % it is always bilateral
                        bilateral = [];
                        thisprediction.confidenceLevel.bilateral=[];
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            obj.progress.Value=obj.progress.Value+size(thisprediction.handles.VTA_Information,2)/(size(thisprediction.handles.VTA_Information,2)*10000);
                            for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %second lead
                                
                                disp(fprintf(status,fXLS,sXLS));
                                sample = [signed_p_map(and(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5,heatmap.pmap>0));...
                                    signed_p_map(and(thisprediction.handles.VTA_Information(2,sXLS).normalizedVTA.Voxels>0.5,heatmap.pmap>0))];
                                % When you take only values which aren't 0 than you get only a worsning or
                                % improving effekt for the prediction.
                                
                                thisprediction.confidenceLevel.bilateral.average(fXLS,sXLS)=thisprediction.confidenceLevel.leftSide.average(1,fXLS)+thisprediction.confidenceLevel.rightSide.average(1,sXLS);
                                h = histogram(sample,edges);
                                distanceFromMeanOfMostLikelyEffekt = [1,zscore(h.Values)];   % normaly just the signed_p_map would be enough, but big VTAs would get a hugh weight in the prediction
                                bilateral(fXLS,sXLS) = distanceFromMeanOfMostLikelyEffekt*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                            end
                        end
                        delete(fig3);
                    end
                    
                case {'heatmapBostonBerlin' , 'heatmapBostonAlone'}
                    % as long as there are no linear regression parameter
                    % given, the prediction is just based on the heatmap
                    % alone
                    probabilityMap=thisprediction.Heatmap.Data.Voxels;
                    linearRegressionCoefficients = 1;  % this are the coefficients for the linear regression model
                    
                    
                    if thisprediction.PositionHemisphere.left==1
                        % unilateral left
                        status='%d. left Lead predicted';
                        unilateral.left = [];
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            disp(fprintf(status,fXLS));
                            sample=probabilityMap(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5);
                            sample=mean(sample);
                            unilateral.left(fXLS) = sample*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                        end
                        sample = probabilityMap(thisprediction.config.FirstLeadrelatedVTA.iVTA>0.5);
                        sample=mean(sample);
                        unilateral.leftVTAPrediction= sample*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                    end
                    
                    if thisprediction.PositionHemisphere.right==1
                        status='%d. right Lead predicted';
                        % unilateral right
                        unilateral.right = [];
                        for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            disp(fprintf(status,sXLS));
                            sample=probabilityMap(thisprediction.handles.VTA_Information(2,sXLS).normalizedVTA.Voxels>0.5);
                            sample=mean(sample);
                            unilateral.right(sXLS) = sample*linearRegressionCoefficients;                        % This fitts the outcomes to the in the filedcase study found values.
                        end
                        sample = probabilityMap(thisprediction.config.SecondLeadrelatedVTA.iVTA>0.5);
                        sample=mean(sample);
                        unilateral.rightVTAPrediction= sample*linearRegressionCoefficients;
                    end
                    
                    if thisprediction.bilateralOn==1
                        status='%d. left Lead and %d. right Lead predicted';
                        bilateral = [];
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            obj.progress.Value=obj.progress.Value+size(thisprediction.handles.VTA_Information,2)/(size(thisprediction.handles.VTA_Information,2)*10000);
                            for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %second lead
                                sample=[probabilityMap(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5);...
                                    probabilityMap(thisprediction.handles.VTA_Information(2,sXLS).normalizedVTA.Voxels>0.5)];
                                sample=mean(mean(sample));
                                disp(fprintf(status,fXLS,sXLS));
                                bilateral(fXLS,sXLS) = sample*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                            end
                        end
                    end
            end
        end
        
        function saveTheData(obj,thisprediction)
            % This functions saves the prediction data and the Date which was used for
            % the prediction. So later on it can be accessed and again shown with
            % 'showTheData'.
            %-----
            %You maybe wonder why the data stored in handles get to a new struct with
            %the same name and I don't say copy collumn whatever to whereever. This is
            %why this sould also work even when more changes are made to the handles
            %struct in whatever way.
            
            %save data as .mat file, for easier later on processing
            currentDirectory=cd;
            cd(thisprediction.Temp)
            PredictionAndVTA.target=thisprediction.handles.target;
            PredictionAndVTA.TransformationLegacySpace=thisprediction.handles.TransformationLegacySpace;
            PredictionAndVTA.VTA_Information=thisprediction.handles.VTA_Information;
            PredictionAndVTA.prediction_Information=thisprediction.handles.prediction_Information;
            PredictionAndVTA.heatmapName=thisprediction.Heatmap.Name;
            PredictionAndVTA.config=thisprediction.config;
            PredictionAndVTA.configStructure=thisprediction.configStructure;
            PredictionAndVTA.Tag=thisprediction.Tag;
            if strcmp(thisprediction.Heatmap.Name,'DystoniaWuerzburg')
            PredictionAndVTA.confidenceLevel=thisprediction.confidenceLevel;
            end
            try
                leadtype=thisprediction.handles.VTA_Information(1,1).monoPolarConfig.leadtype;
            catch
                leadtype=thisprediction.handles.VTA_Information(2,1).monoPolarConfig.leadtype;
            end
            filename=['/', PredictionAndVTA.target,'_',...
                leadtype,'_', ...
                PredictionAndVTA.heatmapName,'_',...
                thisprediction.Tag,'_',...
                num2str(thisprediction.Patient_Information.name),'_', ...
                thisprediction.Patient_Information.gender,'_',...
                num2str(thisprediction.Patient_Information.dateOfBirth(1:10)),'_', ...
                num2str(thisprediction.Patient_Information.patientID)];
            save([thisprediction.Temp,filename,'.mat'],'PredictionAndVTA','-v7.3');
            cd(currentDirectory);
            
            %save only the results and no other data as .csv file
            currentDirectory=cd;
            cd(thisprediction.SavePath)
            filename=filename(2:end);
            numberOfContacts=numel(unique(thisprediction.configStructure.contacts_vector));
            thisprediction.configStructure.numberOfContacts=numberOfContacts;
            numberOfContactSettings=numel(find(~thisprediction.configStructure.contacts_vector));
            thisprediction.configStructure.numberOfContactSettings=numberOfContactSettings;
            
            writematrix('Tag',[filename,'.xls'],'Range','A1','Sheet',2);
            writematrix('Heatmap Name',[filename,'.xls'],'Range','A2','Sheet',2);
            writematrix('Save Directory of .mat',[filename,'.xls'],'Range','A3','Sheet',2);
            writematrix(PredictionAndVTA.Tag,[filename,'.xls'],'Range','B1','Sheet',2);
            writematrix(PredictionAndVTA.heatmapName,[filename,'.xls'],'Range','B2','Sheet',2);
            writematrix(thisprediction.Temp,[filename,'.xls'],'Range','B3','Sheet',2);
            
            startNumber=3;
            writematrix('Bilateral Information',[filename,'.xls'],'Range','A1','Sheet',startNumber);
            try
            writematrix(PredictionAndVTA.prediction_Information.bilateral(1,1:137),[filename,'.xls'],'Range','B1','Sheet',startNumber);
            if numel(thisprediction.configStructure.contacts_vector)>100
                for i=1:numel(thisprediction.configStructure.contacts_vector)/100
                    writematrix(PredictionAndVTA.prediction_Information.bilateral(i+(i-1)*100:i+i*100,:),[filename,'.xls'],'Range','B1','Sheet',startNumber+i-1);
                end
            end
            catch
            writematrix('No bilateral prediction done!',[filename,'.xls'],'Range','B1','Sheet',startNumber);
            end
  
            
            writematrix('Confidence Level',[filename,'.xls'],'Range','A1','Sheet',startNumber+1);
            writematrix('Confidence Level',[filename,'.xls'],'Range','A1','Sheet',startNumber+2);
            
           
            try
                h1_l=thisprediction.confidenceLevel.leftSide.Level.h1;
                h10_l=thisprediction.confidenceLevel.leftSide.Level.h10;
                equal0_l=thisprediction.confidenceLevel.leftSide.Level.equal0;
                leftconfidence=1;
            catch
                leftconfidence=0;
            end
            
            try
                h1_r=thisprediction.confidenceLevel.rightSide.Level.h1;
                h10_r=thisprediction.confidenceLevel.rightSide.Level.h10;
                equal0_r=thisprediction.confidenceLevel.rightSide.Level.equal0;
                rightconfidence=1;
            catch
                rightconfidence=0;
            end
            
            for i=0:numberOfContacts-1
                
                writematrix(['Unilateral Left Information contact',num2str(i)],[filename,'.xls'],'Range',['A',num2str(i+1)],'Sheet',1);
                writematrix(['Unilateral Right Information',num2str(i)],[filename,'.xls'],'Range',['A',num2str(i+1+numberOfContacts)],'Sheet',1);

                
                writematrix(['left h1 contact',num2str(i)],[filename,'.xls'],'Range',[char(66+i),'1'],'Sheet',startNumber+1);
                writematrix(['left h10 contact',num2str(i)],[filename,'.xls'],'Range',[char(66+numberOfContacts+i),'1'],'Sheet',startNumber+1);
                writematrix(['left equal0 contact',num2str(i)],[filename,'.xls'],'Range',[char(66+numberOfContacts*2+i),'1'],'Sheet',startNumber+1);
                writematrix(['right h1 contact',num2str(i)],[filename,'.xls'],'Range',[char(66+i),'1'],'Sheet',startNumber+2);
                writematrix(['right h10 contact',num2str(i)],[filename,'.xls'],'Range',[char(66+numberOfContacts+i),'1'],'Sheet',startNumber+2);
                writematrix(['right equal0 contact',num2str(i)],[filename,'.xls'],'Range',[char(66+numberOfContacts*2+i),'1'],'Sheet',startNumber+2);
                if leftconfidence==1
                    
                    writematrix(PredictionAndVTA.prediction_Information.unilateral.left(1,...
                        1+(numberOfContactSettings*i):numberOfContactSettings+(numberOfContactSettings*i)),...
                    [filename,'.xls'],'Range',['B',num2str(i+1)],'Sheet',1);
                    
                    writematrix(h1_l(1+(numberOfContactSettings*i):numberOfContactSettings+(numberOfContactSettings*i),1),...
                        [filename,'.xls'],'Range',[char(66+i),'2'],'Sheet',startNumber+1);
                    writematrix(h10_l(1+(numberOfContactSettings*i):numberOfContactSettings+(numberOfContactSettings*i),1),...
                        [filename,'.xls'],'Range',[char(66+numberOfContacts+i),'2'],'Sheet',startNumber+1);
                    writematrix(equal0_l(1+(numberOfContactSettings*i):numberOfContactSettings+(numberOfContactSettings*i),1),...
                        [filename,'.xls'],'Range',[char(66+numberOfContacts*2+i),'2'],'Sheet',startNumber+1);
                end
                if rightconfidence==1
                    
                     writematrix(PredictionAndVTA.prediction_Information.unilateral.right(1,...
                        1+(numberOfContactSettings*i):numberOfContactSettings+(numberOfContactSettings*i)),...
                    [filename,'.xls'],'Range',['B',num2str(i+1+numberOfContacts)],'Sheet',startNumber+2);
                
                    writematrix(h1_r(1+(numberOfContactSettings*i):numberOfContactSettings+(numberOfContactSettings*i),1),...
                        [filename,'.xls'],'Range',[char(66+i),'2'],'Sheet',5);
                    writematrix(h10_r(1+(numberOfContactSettings*i):numberOfContactSettings+(numberOfContactSettings*i),1),...
                        [filename,'.xls'],'Range',[char(66+numberOfContacts+i),'2'],'Sheet',startNumber+2);
                    writematrix(equal0_r(1+(numberOfContactSettings*i):numberOfContactSettings+(numberOfContactSettings*i),1),...
                        [filename,'.xls'],'Range',[char(66+numberOfContacts*2+i),'2'],'Sheet',startNumber+2);
                end
            end

            cd(currentDirectory);
        end
        %%
        function showTheData(obj,thisprediction)
            
            contacts_vector = thisprediction.configStructure.contacts_vector;
            amplitudes_vector = thisprediction.configStructure.amplitudes_vector;
            walkthroughs=numel(amplitudes_vector);
            likeTable=0;
            likeGraph=1;
            
            ticklabels = {};
            for i = 1:(walkthroughs)
                ticklabels{i} = ['c = ',num2str(contacts_vector(i)),', amp = ',num2str(amplitudes_vector(i))];
            end
            unilateralticklabels(1,:)=flipud(shiftdim(ticklabels));
            thisprediction.handles.figure=[];
            if thisprediction.PositionHemisphere.left==1
                h1=thisprediction.confidenceLevel.leftSide.Level.h1;
                h10=thisprediction.confidenceLevel.leftSide.Level.h10;
                equal0=thisprediction.confidenceLevel.leftSide.Level.equal0;
                thisprediction.handles.figure.left=figure('Name','Prediction Unilateral Left','Units','normalized','Position',[0.4 0.3 0.7 0.7]);
                showLeftInOtherOrientations=flipud(shiftdim(thisprediction.handles.prediction_Information.unilateral.left)); %this is done, because you do need them in a vertical matrix
                subplot(1,5,1)
                picElectrode=imread('electrodePicture.png');
                imshow(picElectrode);
                set(gca,'Position',[0.05 0.1 0.1 0.8]);
                subplot(1,5,2)
                imagesc(showLeftInOtherOrientations);
                title(thisprediction.handles.VTA_Information(1,1).leadname);
                yticks(1:walkthroughs);
                yticklabels(unilateralticklabels);
                ytickangle(45);
                xticklabels(' ');
                colorbar;
                if strcmp(thisprediction.Heatmap.Name,'heatmapBostonBerlin')||strcmp(thisprediction.Heatmap.Name,'heatmapBostonAlone')
                    caxis([0.3 1.2]);
                else
                caxis([30 110]);
                end 
                set(gca,'Position',[0.25 0.1 0.03 0.8]);
                if likeGraph==1
                    xnames={};
                    for i=1:thisprediction.configStructure.numberOfContactSettings
                    xnames{1,i}=thisprediction.configStructure.amplitudes_vector(1,i);
                    end
                   subplot(3,5,13)
                   hold on
                   for i=0:thisprediction.configStructure.numberOfContacts-1
                       plot(1:thisprediction.configStructure.numberOfContactSettings,...
                           h10(1+i*thisprediction.configStructure.numberOfContactSettings:(i+1)*thisprediction.configStructure.numberOfContactSettings),'DisplayName',['contact',num2str(i)]);
                   end
                   set(gca,'Position',[0.35 0.1 0.6 0.2])
                   xticks(1:thisprediction.configStructure.numberOfContactSettings);
                   xticklabels(xnames);
                   title('Confidence Level more than 10 VTAs per Voxel');
                   legend;
                   ylim([-2 inf]);
                   ylabel('%');
                   xlabel('mA');
                   hold off
                    subplot(3,5,8)
                    hold on
                   for i=0:thisprediction.configStructure.numberOfContacts-1
                       plot(1:thisprediction.configStructure.numberOfContactSettings,...
                           h1(1+i*thisprediction.configStructure.numberOfContactSettings:(i+1)*thisprediction.configStructure.numberOfContactSettings),'DisplayName',['contact',num2str(i)]);
                   end
                   set(gca,'Position',[0.35 0.4 0.6 0.2])
                   xticks(1:thisprediction.configStructure.numberOfContactSettings);
                   xticklabels(xnames);
                   title('Confidence Level more than 1 VTA and less than 10 VTAs per Voxel');
                   legend;
                   ylim([-2 inf]);
                   ylabel('%');
                   xlabel('mA');
                   hold off
                    subplot(3,5,3)
                    hold on
                   for i=0:thisprediction.configStructure.numberOfContacts-1
                       plot(1:thisprediction.configStructure.numberOfContactSettings,...
                           equal0(1+i*thisprediction.configStructure.numberOfContactSettings:(i+1)*thisprediction.configStructure.numberOfContactSettings),'DisplayName',['contact',num2str(i)]);
                   end
                   set(gca,'Position',[0.35 0.76 0.6 0.2])
                   xticks(1:thisprediction.configStructure.numberOfContactSettings);
                   xticklabels(xnames);
                   title('Confidence Level no VTA per Voxel');
                   legend;
                   ylim([-2 inf]);
                   ylabel('%');
                   xlabel('mA');
                   hold off
                elseif likeTable==1
                t=table(flipud(h10));
                name={'more than 10'};
                uitable('Data',t{:,:},'RowName',unilateralticklabels,'ColumnName',name,...
                    'Units','normalized','Position',[0.29 0.01 0.24 0.9]);
                t=table(flipud(h1));
                name={'more 1 less 10'};
                uitable('Data',t{:,:},'RowName',unilateralticklabels,'ColumnName',name,...
                    'Units','normalized','Position',[0.52 0.01 0.24 0.9]);
                t=table(flipud(equal0));
                name={'equal to zero'};
                uitable('Data',t{:,:},'RowName',unilateralticklabels,'ColumnName',name,...
                    'Units','normalized','Position',[0.76 0.01 0.24 0.9]);
                end
            end
            
            if thisprediction.PositionHemisphere.right==1
                h1=thisprediction.confidenceLevel.rightSide.Level.h1;
                h10=thisprediction.confidenceLevel.rightSide.Level.h10;
                equal0=thisprediction.confidenceLevel.rightSide.Level.equal0;
                thisprediction.handles.figure.right=figure('Name','Prediction Unilateral Right','Units','normalized','Position',[0.4 0.3 0.7 0.7]);
                subplot(1,5,1)
                picElectrode=imread('electrodePicture.png');
                imshow(picElectrode);
                set(gca,'Position',[0.03 0.1 0.1 0.8]);
                subplot(1,5,2)
                rightside(:,1)=thisprediction.handles.prediction_Information.unilateral.right;
                imagesc(flipud(rightside));
                title(thisprediction.handles.VTA_Information(2,1).leadname);
                yticks(1:walkthroughs);
                yticklabels(unilateralticklabels);
                ytickangle(45);
                xticklabels(' ');
                colorbar;
                if strcmp(thisprediction.Heatmap.Name,'heatmapBostonBerlin')||strcmp(thisprediction.Heatmap.Name,'heatmapBostonAlone')
                    caxis([0.3 1.2]);
                else
                caxis([30 110]);
                end
                set(gca,'Position',[0.2 0.1 0.03 0.8]);
                if likeGraph==1
                     xnames={};
                    for i=1:thisprediction.configStructure.numberOfContactSettings
                    xnames{1,i}=thisprediction.configStructure.amplitudes_vector(1,i);
                    end
                   subplot(3,5,13)
                   hold on
                   for i=0:thisprediction.configStructure.numberOfContacts-1
                       plot(1:thisprediction.configStructure.numberOfContactSettings,...
                           h10(1+i*thisprediction.configStructure.numberOfContactSettings:(i+1)*thisprediction.configStructure.numberOfContactSettings),'DisplayName',['contact',num2str(i)]);
                   end
                   set(gca,'Position',[0.35 0.1 0.6 0.2])
                   xticks(1:thisprediction.configStructure.numberOfContactSettings);
                   xticklabels(xnames);
                   title('Confidence Level more than 10 VTAs per Voxel');
                   legend;
                   ylim([-2 inf]);
                   ylabel('%');
                   xlabel('mA');
                   hold off
                    subplot(3,5,8)
                    hold on
                   for i=0:thisprediction.configStructure.numberOfContacts-1
                       plot(1:thisprediction.configStructure.numberOfContactSettings,...
                           h1(1+i*thisprediction.configStructure.numberOfContactSettings:(i+1)*thisprediction.configStructure.numberOfContactSettings),'DisplayName',['contact',num2str(i)]);
                   end
                   set(gca,'Position',[0.35 0.4 0.6 0.2])
                   xticks(1:thisprediction.configStructure.numberOfContactSettings);
                   xticklabels(xnames);
                   title('Confidence Level more than 1 VTA and less than 10 VTAs per Voxel');
                   legend;
                   ylim([-2 inf]);
                   ylabel('%');
                   xlabel('mA');
                   hold off
                    subplot(3,5,3)
                    hold on
                   for i=0:thisprediction.configStructure.numberOfContacts-1
                       plot(1:thisprediction.configStructure.numberOfContactSettings,...
                           equal0(1+i*thisprediction.configStructure.numberOfContactSettings:(i+1)*thisprediction.configStructure.numberOfContactSettings),'DisplayName',['contact',num2str(i)]);
                   end
                   set(gca,'Position',[0.35 0.76 0.6 0.2])
                   xticks(1:thisprediction.configStructure.numberOfContactSettings);
                   xticklabels(xnames);
                   title('Confidence Level no VTA per Voxel');
                   legend;
                   ylim([-2 inf]);
                   ylabel('%');
                   xlabel('mA');
                   hold off
                elseif likeTable==1
                t=table(flipud(h10));
                name={'more than 10'};
                uitable('Data',t{:,:},'RowName',unilateralticklabels,'ColumnName',name,...
                    'Units','normalized','Position',[0.29 0.01 0.24 0.9]);
                t=table(flipud(h1));
                name={'more 1 less 10'};
                uitable('Data',t{:,:},'RowName',unilateralticklabels,'ColumnName',name,...
                    'Units','normalized','Position',[0.52 0.01 0.24 0.9]);
                t=table(flipud(equal0));
                name={'equal to zero'};
                uitable('Data',t{:,:},'RowName',unilateralticklabels,'ColumnName',name,...
                    'Units','normalized','Position',[0.76 0.01 0.24 0.9]);
                end
            end
            
            if thisprediction.bilateralOn==1
                thisprediction.handles.figure.bilateral=figure('Name','Prediction','Units','normalized','Position',[0.2 0.3 0.7 0.7]);
                subplot(1,5,1)
                picElectrode=imread('electrodePicture.png');
                imshow(picElectrode);
                set(gca,'Position',[0.02 0.05 0.1 0.8]);
                subplot(1,5,5)
                imagesc(thisprediction.handles.prediction_Information.bilateral);
                ylabel(thisprediction.handles.VTA_Information(1,1).leadname);
                xlabel(thisprediction.handles.VTA_Information(2,1).leadname);
                xticks(1:walkthroughs);
                xticklabels(ticklabels);
                yticks(1:walkthroughs);
                yticklabels(ticklabels);
                xtickangle(45);
                ytickangle(0);
                colorbar;
                if strcmp(thisprediction.Heatmap.Name,'heatmapBostonBerlin')||strcmp(thisprediction.Heatmap.Name,'heatmapBostonAlone')
                    caxis([0.3 1.2]);
                else
                caxis([30 110]);
                end
                set(gca,'Position',[0.32 0.15 0.6 0.8]);
            end
        end
    end
end

