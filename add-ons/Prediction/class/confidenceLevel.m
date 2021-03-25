classdef confidenceLevel<handle
    %This class is used to calculate a confidence value, which is taken in
    %reference when the results are displayed later on. 
    
    properties
        left
        right
        leftVTAPatient
        rightVTAPatient
        bilateral
        side
    end
    
    methods
        function obj = confidenceLevel()
            %Needs to be here...
        end
        
        function sampleToRealMNI(obj,heatmap,sizeOfArray)
            % The original map for creating the heatmap was constructed in
            % a wrong space, the so called legacy MNI space. That is why it
            % needs to be transformed.
            sampleToTransform=VoxelData;
            Tlegacy2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
            
            if strcmp(heatmap.Name,'DystoniaWuerzburg')
                sampleToTransform=sampleToTransform.loadnii('DystoniaMapWürzburg_forDecisionOfQuality.nii',1);
                R=sampleToTransform.R;
                R.XWorldLimits = [-7.5 7.5];
                R.YWorldLimits = [-7.5 7.5];
                I=sampleToTransform.Voxels;
                T=affine3d(Tlegacy2mni);
                [sampleToTransform.Voxels,sampleToTransform.R] = imwarp(I,R,T);
                sampleToTransform.Voxels(isnan(sampleToTransform.Voxels)) = 0;
                
                if obj.side.left==1
                    if isempty(obj.left)
                        obj.left.Map=sampleToTransform.Voxels;
                        obj.side.left=0;
                        obj.left.average=zeros(1,sizeOfArray);
                    end
                elseif obj.side.right==1
                    if isempty(obj.right)
                        obj.right.Map=sampleToTransform.Voxels;
                        obj.side.right=0;
                        obj.right.average=zeros(1,sizeOfArray);
                    end
                else
                    delete(findobj('Name','Prediction Enviroment'));
                    error('No hemisphere definition found!')
                end
            end   
        end
        
        function calculationConfidenceLevel(obj,VTA,counter,heatmap)
            %This is needed, because the average amount of VTA scores used
            %for each single Voxels is determind here. 
            
            if isa(counter,'char')
                name=counter;
            else
                if not(isempty(obj.right)) && obj.right.average(1,counter)==0 
                    name='right';
                elseif not(isempty(obj.left)) && obj.left.average(1,counter)==0 
                    name='left';
                end
            end
            
                allVTAsAcounted=(VTA>0.5) & (heatmap.pmap>0);
                allUsedOriginVTAs=obj.(name).Map.*allVTAsAcounted;
                finalSum=sum(allUsedOriginVTAs,'all');
                sumOfValues=find(allVTAsAcounted);
                sumOfValues=numel(sumOfValues);
                if isa(counter,'char')
                    if strcmp(counter,'left')
                        obj.leftVTAPatient=finalSum/sumOfValues;
                    elseif strcmp(counter,'right')
                        obj.rightVTAPatient=finalSum/sumOfValues;
                    end
                    return;
                end
                obj.(name).average(1,counter)=finalSum/sumOfValues;
        end
    end
end

