classdef buttonConnected<handle
    % All to the button connected functions go here.
    
    properties
        
    end
    
    methods
        function [Excel_output,Patient_Information,result]=VTA_Transformation(obj,thisprediction)
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
                save(fullfile(folder.path,'/predictionConfig'),'predictionConfig');
            else
                config=load('predictionConfig.mat');
                thisprediction.VTAPoolPath=config.predictionConfig.VTAPoolPath;
                thisprediction.SavePath=config.predictionConfig.SavePath;
            end
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
                    thisprediction.config=lead.config;
                end
                
                % Finding of Transformation data
                    % it matters which electrode you choose, thats what the
                    % NumberOfLead is for
                    stimPlanNumber(1,1)=thisprediction.config.NumberOfFirstLead;
                    try
                    stimPlanNumber(1,2)=stimPlanNumber(1,1)+thisprediction.config.NumberOfSecondLead;
                    catch
                    end
                    for istimPlanNumber=1:numel(stimPlanNumber)
                    loop_therapyPlanStorage=thisSession.therapyPlanStorage{stimPlanNumber(istimPlanNumber)};
                    loop_atlas=lead.getMatchingAtlas(loop_therapyPlanStorage,thisSession,thisprediction);
                    atlas{istimPlanNumber}=loop_atlas;
                    %Transformation from electrode space to selected atlas
                    %space
                    T_vta_to_atlas = thisSession.gettransformfromto(loop_therapyPlanStorage.lead,loop_atlas);
                    T_atlas_to_legacySpace= lead.findTtolegacySpace(loop_therapyPlanStorage,thisprediction.handles.target);
                    thisprediction.handles.TransformationLegacySpace{istimPlanNumber} =...            % this is the euqivalent of XLS.Tlead2MNI.value
                        T_vta_to_atlas*T_atlas_to_legacySpace;          %If this value of correctness is not needed it can be shortened with round()
                    end
                
                % VTA with Information is created
                status='%d. Lead and %d. Contactcombination for aligning monopolar VTAs to sweetspot...';
                
                Excel_output=[];
                
                %for now on you can work with Boston or Medtronic leads and its
                %configuration data
                
                lead.getConfiguration(thisSession);
                thisprediction.config=lead.config;
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
                
                for iLead =1:numel(stimPlanNumber)
                    % Everything which is needed for each single VTA
                    thisLead = thisSession.getregisterable(leadidcs(1,iLead));
                    for iStimplan = 1:numel(thisLead.stimPlan)
                        lead.ExporttoVTApool(thisprediction,thisLead.stimPlan{iStimplan});
                    end
                    [Ivta,Rvta]=lead.getVTAInformation(thisLead.stimPlan{1});
                    thisVTA={Ivta,Rvta};
                    for iMonoPolar = 1:numel(lead.config.amplitudes_vector)
                        disp(fprintf(status,iLead,iMonoPolar));
                        
                                                data.leadtype='Medtronic3389';
                                                data.pulsewidth='60';
                                                data.voltage='False';
                                                data.groundedcontact = '0 0 0 0';
                        
%                         data.leadtype= thisSession.therapyPlanStorage{1, iLead}.lead.leadType; %this is like how it should be with a bigger vta pool
%                         data.voltage = thisSession.therapyPlanStorage{1, iLead}.voltageBasedStimulation;
%                         data.pulsewidth = thisSession.therapyPlanStorage{1, iLead}.pulseWidth;
%                         data.groundedcontact = thisSession.therapyPlanStorage{1, iLead}.contactsGrounded;
%                         
                        data.amplitude = num2str(lead.config.amplitudes_vector(iMonoPolar));
                        activevector = lead.config.activevector;
                        activevector(lead.config.contacts_vector(iMonoPolar)+1) = 1;
                        data.activecontact = strrep(num2str(activevector),'  ',' ');
                        
                        Excel_output(iLead,iMonoPolar).monoPolarConfig = data;
                        Excel_output(iLead,iMonoPolar).leadname = thisSession.therapyPlanStorage{1,iLead}.lead.label;
                        
                        if ~strcmp(thisSession.therapyPlanStorage{1, iLead}.activeRings,activevector)% If in the loaded dataset the needed configuration of active contacts is not given, then load it from earlier sessions.
                            try
                                thisVTA = lead.loadVTA(data,thisprediction.VTAPoolPath); %loads what was created with the makerecipeCodeMac
                            catch
                                error(['No matching VTA was found in the VTA Pool Path!', 'Please make sure you have all possibilities as VTAs!',newline,...
                                    'If you do not understand what is the issue here, please ask Tim!']);
                            end
                        end
                        
                        [iVTA,rVTA] = lead.getVTAInMNISpace(thisVTA,thisprediction,...
                            thisprediction.handles.TransformationLegacySpace{1,iLead},atlas{1,iLead}.hemisphere);
                        
                        if max(iVTA(:)) == 0
                            warning('OUT OF RANGE')
                        end
                        
                        Excel_output(iLead,iMonoPolar).normalizedVTA.Voxels = single(iVTA>0.5);    %voxels as only greater than 0.5 of all iVTA data
                        Excel_output(iLead,iMonoPolar).normalizedVTA.Imref = rVTA;
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
                    
                    
                    if thisprediction.unilateralOn || thisprediction.PositionHemisphere==0
                        status='%d. left Lead predicted';
                        fig1=figure('Name','Monopolar_Histogramm-Left');
                        % it is always bilateral
                        unilateral.left = [];
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            disp(fprintf(status,fXLS));
                            sample = signed_p_map(and(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5,heatmap.pmap>0));
                            % When you take only values which aren't 0 than you get only a worsening or
                            % improving effekt for the prediction.
                            
                            h = histogram(sample,edges);
                            distanceFromMeanOfMostLikelyEffekt = [1,zscore(h.Values)];   % normaly just the signed_p_map would be enough, but big VTAs would get a hugh weight in the prediction
                            unilateral.left(fXLS) = distanceFromMeanOfMostLikelyEffekt*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                        end
                        delete(fig1)
                    end
                    
                    if thisprediction.unilateralOn || thisprediction.PositionHemisphere==1
                        status='%d. right Lead predicted';
                        fig2=figure('Name','Monopolar_Histogramm-Right');
                        % it is always bilateral
                        unilateral.right = [];
                        for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            disp(fprintf(status,sXLS));
                            sample = signed_p_map(and(thisprediction.handles.VTA_Information(1,sXLS).normalizedVTA.Voxels>0.5,heatmap.pmap>0));
                            % When you take only values which aren't 0 than you get only a worsening or
                            % improving effekt for the prediction.
                            
                            h = histogram(sample,edges);
                            distanceFromMeanOfMostLikelyEffekt = [1,zscore(h.Values)];   % normaly just the signed_p_map would be enough, but big VTAs would get a hugh weight in the prediction
                            unilateral.right(sXLS) = distanceFromMeanOfMostLikelyEffekt*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                        end
                        delete(fig2)
                    end
                    
                    if thisprediction.bilateralOn==1
                        status='%d. left Lead and %d. right Lead predicted';
                        fig3=figure('Name','Bilateral_Histogramm');
                        % it is always bilateral
                        bilateral = [];
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %second lead
                                
                                disp(fprintf(status,fXLS,sXLS));
                                sample = [signed_p_map(and(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5,heatmap.pmap>0));...
                                    signed_p_map(and(thisprediction.handles.VTA_Information(2,sXLS).normalizedVTA.Voxels>0.5,heatmap.pmap>0))];
                                % When you take only values which aren't 0 than you get only a worsning or
                                % improving effekt for the prediction.
                                
                                h = histogram(sample,edges);
                                distanceFromMeanOfMostLikelyEffekt = [1,zscore(h.Values)];   % normaly just the signed_p_map would be enough, but big VTAs would get a hugh weight in the prediction
                                bilateral(fXLS,sXLS) = distanceFromMeanOfMostLikelyEffekt*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                            end
                        end
                        delete(fig3);
                    end
                    
                case 'heatmapBostonBerlin'
                    % as long as there are no linear regression parameter
                    % given, the prediction is just based on the heatmap
                    % alone
                    probabilityMap=thisprediction.Heatmap.Data.Voxels;
                    linearRegressionCoefficients = 1;  % this are the coefficients for the linear regression model
                    
                    
                    
                    if thisprediction.unilateralOn || thisprediction.PositionHemisphere==0
                        % unilateral left
                        status='%d. left Lead predicted';
                        unilateral.left = [];
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            disp(fprintf(status,fXLS));
                            sample=probabilityMap(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5);
                            sample=mean(sample);
                            unilateral.left(fXLS) = sample;%*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                        end
                    end
                    
                    if thisprediction.unilateralOn || thisprediction.PositionHemisphere==1
                        status='%d. right Lead predicted';
                        % unilateral right
                        unilateral.right = [];
                        for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            disp(fprintf(status,sXLS));
                            sample=probabilityMap(thisprediction.handles.VTA_Information(1,sXLS).normalizedVTA.Voxels>0.5);
                            sample=mean(sample);
                            unilateral.left(sXLS) = sample;%*linearRegressionCoefficients;                        % This fitts the outcomes to the in the filedcase study found values.
                        end
                    end
                    
                    if thisprediction.bilateralOn==1
                        status='%d. left Lead and %d. right Lead predicted';
                        bilateral = [];
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %second lead
                                sample=[probabilityMap(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5);...
                                    probabilityMap(thisprediction.handles.VTA_Information(1,sXLS).normalizedVTA.Voxels>0.5)];
                                sample=mean(mean(sample));
                                disp(fprintf(status,fXLS,sXLS));
                                bilateral(fXLS,sXLS) = sample;%*linearRegressionCoefficients                    % This fitts the outcomes to the in the filedcase study found values.
                            end
                        end
                    end
                    
                case 'heatmapBostonAlone'
                    % as long as there are no linear regression parameter
                    % given, the prediction is just based on the heatmap
                    % alone
                    probabilityMap=thisprediction.Heatmap.Data.Voxels;
                    linearRegressionCoefficients = 1;  % this are the coefficients for the linear regression model
                    
                    status='%d. left Lead predicted';
                    
                    if thisprediction.unilateralOn || thisprediction.PositionHemisphere==0
                        % unilateral left
                        unilateral.left = [];
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            disp(fprintf(status,fXLS));
                            sample=probabilityMap(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5);
                            sample=mean(sample);
                            unilateral.left(fXLS) = sample;%*linearRegressionCoefficients                      % This fitts the outcomes to the in the filedcase study found values.
                        end
                    end
                    
                    if thisprediction.unilateralOn || thisprediction.PositionHemisphere==1
                        status='%d. right Lead predicted';
                        % unilateral right
                        unilateral.right = [];
                        for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            sample=probabilityMap(thisprediction.handles.VTA_Information(1,sXLS).normalizedVTA.Voxels>0.5);
                            disp(fprintf(status,sXLS));
                            sample=mean(sample);
                            unilateral.left(sXLS) = sample;%*linearRegressionCoefficients                          % This fitts the outcomes to the in the filedcase study found values.
                        end
                    end
                    
                    if thisprediction.bilateralOn==1
                        status='%d. left Lead and %d. right Lead predicted';
                        bilateral = [];
                        for fXLS = 1:size(thisprediction.handles.VTA_Information,2) %first lead
                            for sXLS = 1:size(thisprediction.handles.VTA_Information,2) %second lead
                                sample=[probabilityMap(thisprediction.handles.VTA_Information(1,fXLS).normalizedVTA.Voxels>0.5);...
                                    probabilityMap(thisprediction.handles.VTA_Information(1,sXLS).normalizedVTA.Voxels>0.5)];
                                sample=mean(mean(sample));
                                disp(fprintf(status,fXLS,sXLS));
                                bilateral(fXLS,sXLS) = sample;%*linearRegressionCoefficients                      % This fitts the outcomes to the in the filedcase study found values.
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
            
            PredictionAndVTA.target=thisprediction.handles.target;
            PredictionAndVTA.TransformationLegacySpace=thisprediction.handles.TransformationLegacySpace;
            PredictionAndVTA.VTA_Information=thisprediction.handles.VTA_Information;
            PredictionAndVTA.prediction_Information=thisprediction.handles.prediction_Information;
            PredictionAndVTA.heatmapName=thisprediction.Heatmap.Name;
            PredictionAndVTA.config=thisprediction.config;
            PredictionAndVTA.Tag=thisprediction.Tag;
            filename=['/', PredictionAndVTA.target,'_',...
                thisprediction.handles.VTA_Information(1, 1).monoPolarConfig.leadtype,'_', ...
                PredictionAndVTA.heatmapName,'_',...
                thisprediction.Tag,'_',...
                num2str(thisprediction.Patient_Information.name),'_', ...
                thisprediction.Patient_Information.gender,'_',...
                num2str(thisprediction.Patient_Information.dateOfBirth(1:10)),'_', ...
                num2str(thisprediction.Patient_Information.patientID),'.mat'];
            save(fullfile(thisprediction.SavePath,filename),'PredictionAndVTA');
        end
        %%
        function showTheData(obj,thisprediction)
            
            contacts_vector = thisprediction.config.contacts_vector;
            amplitudes_vector = thisprediction.config.amplitudes_vector;
            walkthroughs=numel(amplitudes_vector);
            
            ticklabels = {};
            for i = 1:(walkthroughs)
                ticklabels{i} = ['c = ',num2str(contacts_vector(i)),', amp = ',num2str(amplitudes_vector(i))];
            end
            thisprediction.handles.figure=[];
            if thisprediction.unilateralOn || thisprediction.PositionHemisphere==0
                thisprediction.handles.figure.left=figure('Name','Prediction Unilateral Left');
                showLeftInOtherOrientations=shiftdim(thisprediction.handles.prediction_Information.unilateral.left); %this is done, because you do need them in a vertical matrix
                imagesc(showLeftInOtherOrientations);
                ylabel(thisprediction.handles.VTA_Information(1,1).leadname);
                yticks(1:walkthroughs);
                yticklabels(ticklabels);
                ytickangle(45);
                xticklabels(' ');
            end
            
            if thisprediction.unilateralOn || thisprediction.PositionHemisphere==1
                thisprediction.handles.figure.right=figure('Name','Prediction Unilateral Right');
                imagesc(thisprediction.handles.prediction_Information.unilateral.right);
                xlabel(thisprediction.handles.VTA_Information(1,1).leadname);
                xticks(1:walkthroughs);
                xticklabels(ticklabels);
                xtickangle(45);
                yticklabels(' ');
            end
            
            if thisprediction.bilateralOn==1
                thisprediction.handles.figure.bilateral=figure('Name','Prediction');
                imagesc(thisprediction.handles.prediction_Information.bilateral);
                ylabel(thisprediction.handles.VTA_Information(1,1).leadname);
                xlabel(thisprediction.handles.VTA_Information(2,1).leadname);
                xticks(1:walkthroughs);
                xticklabels(ticklabels);
                yticks(1:walkthroughs);
                yticklabels(ticklabels);
                xtickangle(45);
                ytickangle(0);
            end
        end
        
    end
end

