load('memory_Bilateral_GPI_GEN+CER.swtspt','-mat');
%%
sampleToTransform=VoxelData;
Tlegacy2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
sampleToTransform=sampleToTransform.loadnii('DystoniaMapWürzburg_forDecisionOfQuality.nii',1);
R=sampleToTransform.R;
R.XWorldLimits = [-7.5 7.5];
R.YWorldLimits = [-7.5 7.5];
I=sampleToTransform.Voxels;
T=affine3d(Tlegacy2mni);
[sampleToTransform.Voxels,sampleToTransform.R] = imwarp(I,R,T);
sampleToTransform.Voxels(isnan(sampleToTransform.Voxels)) = 0;

%%
T_Data=VoxelData;
P_Data=VoxelData;
T_Data.loadnii('BilateralSweetspot_t_p_average_realMNI_nii_tValue.nii',1);
P_Data.loadnii('BilateralSweetspot_t_p_average_realMNI_nii_pValue.nii',1);
heatmap.tmap = T_Data.Voxels;
heatmap.pmap = P_Data.Voxels;

for i=1:numel(sweetspot.dataleft(1,1,1,:))
VTA=sweetspot.dataleft(:,:,:,i);
Voxels=VTA;

R=imref3d([200 204 208],0.25,0.25,0.25);
R.XWorldLimits=sweetspot.originMNIleft(1,1)+R.XWorldLimits-0.25;
R.YWorldLimits=sweetspot.originMNIleft(1,2)+R.YWorldLimits-0.25;
R.ZWorldLimits=sweetspot.originMNIleft(1,3)+R.ZWorldLimits-0.25;
            

[Voxels,R] = imwarp(Voxels,R,T);
Voxels(isnan(Voxels)) = 0;
VTA=Voxels;

allVTAsAcounted=(VTA>0.5) & (heatmap.pmap>0);

allUsedOriginVTAs=sampleToTransform.Voxels.*allVTAsAcounted;
finalSum=sum(allUsedOriginVTAs,'all');
sumOfValues=find(allVTAsAcounted);
sumOfValues=numel(sumOfValues);
average(i,1)=finalSum/sumOfValues;
end

%%
averageToSave.confidenceLevel=average;
averageToSave.twoStanardDeviationPlus=mean(average)+2*std(average);
averageToSave.oneStanardDeviationPlus=mean(average)+std(average);
averageToSave.twoStanardDeviationMinus=mean(average)-2*std(average);
averageToSave.oneStanardDeviationMinus=mean(average)-std(average);

%% this is the code for the range of the stimulation
load('Bilateral_GPI_GEN+CER.swtspt','-mat')
useableAmplitude=[];
for i=1:numel(sweetspot.raw) %when a level is set to voltage controlled, the clinician selected the wrong method
    useableAmplitude(end+1,1)=sweetspot.raw(1,i).amplitude;
end

% figure;
% boxplot(useableAmplitude);
% figure;
% hist(useableAmplitude)

% figure;
% scatter(((rand(158,1)-0.5)/4)+1,useableAmplitude);
% hold on 
% boxplot(useableAmplitude);
% 
% figure;
% scatter(x,k);
averageToSave.AmplitudesOriginal=useableAmplitude;
averageToSave.usableAmplitudeMinusTwoStd=mean(useableAmplitude)-2*std(useableAmplitude);
averageToSave.usableAmplitudeMinusOneStd=mean(useableAmplitude)-std(useableAmplitude);
averageToSave.usableAmplitudePlusTwoStd=mean(useableAmplitude)+2*std(useableAmplitude);
averageToSave.usableAmplitudePlusOneStd=mean(useableAmplitude)+std(useableAmplitude);

save('memoryFile_AmplitudeSetting_ConfidenceThreshold_TrialDystoniaWürzburg.mat','averageToSave');
