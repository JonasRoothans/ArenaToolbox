classdef predictSingleVTA<handle
    %This class itself is used to make a prediction for one single VTA
    %possible.
    
    properties
        Tag
    end
    
    methods
        function obj = predictSingleVTA()
            %This needs to be here!;
        end
        
        function newPrediction(obj,thisprediction)
            %Inside this methode all necessary preparations are made for a
            %prediction.
             edges = -1:0.13333333333:1;
            unilateral=[];
            
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
                        
                        interpolatedVTA=thisprediction.Results.interpolateVTAToRightReferences(thisprediction);
                        linearRegressionCoefficients = [57.6598809951595;12.0664757620877;15.6438035692808;...
                        4.57530292424259;-3.13275389368958;-14.8795376587032;...
                        -14.5891044360106;0;16.9708673876284;12.6398172008286;...
                        8.23591228720219;13.9285582004609;4.62858440753228;...
                        -25.9956758412821;17.0527413996103;8.60861313752535];   % this are the coefficients for the linear regression model
                    
                    heatmap.tmap = thisprediction.Heatmap.T_Data.Voxels;
                    heatmap.pmap = thisprediction.Heatmap.P_Data.Voxels;
                    signed_p_map = (1-heatmap.pmap).*sign(heatmap.tmap);
                    sample = signed_p_map(and(interpolatedVTA>0.5,heatmap.pmap>0));
                    % When you take only values which aren't 0 than you get only a worsening or
                    % improving effekt for the prediction.
                    
                    fig1=figure;
                    h = histogram(sample,edges);
                    distanceFromMeanOfMostLikelyEffekt = [1,zscore(h.Values)];   % normaly just the signed_p_map would be enough, but big VTAs would get a hugh weight in the prediction
                    unilateral = distanceFromMeanOfMostLikelyEffekt*linearRegressionCoefficients;
                    delete(fig1);
                    disp('The accuracy is not completely correct to the prediction done on a lead. Normaly the results differ around 5%.')
                    
                case 'heatmapBostonBerlin'
                        %Please never switch reslicing off with the
                        %BostonBerlin Heatmap!
                        % This would destroy your result, because the
                        % original data lives in the wrong space!
                        thisprediction.Heatmap.Data=VoxelData;
                        thisprediction.Heatmap.Data.loadnii('BER_MDST_UPDRS_corrdata_exch_palm_vox_vstat_R_Fz_yeo1000_dil_map.nii');
                        interpolatedVTA=thisprediction.Results.interpolateVTAToRightReferences(thisprediction);
                        % as long as there are no linear regression parameter
                    % given, the prediction is just based on the heatmap
                    % alone
                    probabilityMap=thisprediction.Heatmap.Data.Voxels;
                    linearRegressionCoefficients = 1;  % this are the coefficients for the linear regression model
                    sample=probabilityMap(interpolatedVTA>0.5);
                    sample=mean(sample);
                    unilateral = sample*linearRegressionCoefficients;%*linearRegressionCoefficients;                    % This fitts the outcomes to the in the filedcase study found values.
                    
                case 'heatmapBostonAlone'
                        %Please never switch reslicing off with the
                        %BostonAlone Heatmap!
                        % This would destroy your result, because the
                        % original data lives in the wrong space!
                        thisprediction.Heatmap.Data=VoxelData;
                        thisprediction.Heatmap.Data.loadnii('cogdec_SE_vs_noSE_orig_fz_use_design_palm_vox_tstat_yeo1000_dil_precomputed_corr_R_Fz.nii');
                        interpolatedVTA=thisprediction.Results.interpolateVTAToRightReferences(thisprediction);
                        % as long as there are no linear regression parameter
                    % given, the prediction is just based on the heatmap
                    % alone
                    probabilityMap=thisprediction.Heatmap.Data.Voxels;
                    linearRegressionCoefficients = 1;  % this are the coefficients for the linear regression model
                    sample=probabilityMap(interpolatedVTA>0.5);
                    sample=mean(sample);
                    unilateral = sample*linearRegressionCoefficients;%*linearRegressionCoefficients    
                     % This fitts the outcomes to the in the filedcase study found values.
                otherwise
                        disp('You did not select a Heatmap which can be used!');
            end
            thisprediction.Tag=[' # ',num2str(round(unilateral,5))];
            delete(findobj('Name','Prediction Enviroment'));
        end
        
        function interpolatedVTA=interpolateVTAToRightReferences(obj,thisprediction)
            try
                Rpsm=thisprediction.Heatmap.T_Data.R;
            catch
                Rpsm=thisprediction.Heatmap.Data.R;
            end
            Rwarp=thisprediction.Data_In.Source.R;
            Iwarp=thisprediction.Data_In.Source.Voxels;
            %make a meshgrid of reference of Legacyspace in specific dimensions
            [xq,yq,zq] = imref2meshgrid(Rpsm);
            %make a meshgrid of input
            [x,y,z] = imref2meshgrid(Rwarp);            %is only to overlay both
            
            %Resample
            interpolatedVTA = interp3(x,y,z,Iwarp,xq,yq,zq);       % the input data doesn't perfectly fit with the original data samples,
            %thats why it needs to be interpolated
            disp('Transformation, Mirroring and Interpolation done!');
            %delete Nans
            interpolatedVTA(isnan(interpolatedVTA)) = 0;
        end
    end
end

