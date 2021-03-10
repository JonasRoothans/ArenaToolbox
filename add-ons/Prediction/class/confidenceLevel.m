classdef confidenceLevel<handle
    %This class is used to calculate a confidence value, which is taken in
    %reference when the results are displayed later on. 
    
    properties
        leftSide
        rightSide
        bilateral
        side
    end
    
    methods
        function obj = confidenceLevel()
            %Needs to be here...
        end
        
        function sampleToRealMNI(obj,heatmap,number)
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
                    if isempty(obj.leftSide)
                        obj.leftSide.Map=sampleToTransform.Voxels;
                        obj.leftSide.Level=[];
                        obj.leftSide.Level.h10=zeros(number,1);
                        obj.leftSide.Level.h1=zeros(number,1);
                        obj.leftSide.Level.equal0=zeros(number,1);
                        obj.side.left=0;
                    end
                elseif obj.side.right==1
                    if isempty(obj.rightSide)
                        obj.rightSide.Map=sampleToTransform.Voxels;
                        obj.rightSide.Level=[];
                        obj.rightSide.Level.h10=zeros(number,1);
                        obj.rightSide.Level.h1=zeros(number,1);
                        obj.rightSide.Level.equal0=zeros(number,1);
                        obj.side.right=0;
                    end
                else
                    error('No hemisphere definition found!')
                end
            end
            
            
        end
        
        function calculationConfidenceLevel(obj,VTA,counter,heatmap)
            %This is needed, because the average amount of VTA scores used
            %for each single Voxels is determind here. 
            
            if not(isempty(obj.rightSide)) && obj.rightSide.Level.h10(counter,1)==0
                name='rightSide';
            elseif not(isempty(obj.leftSide)) && obj.leftSide.Level.h10(counter,1)==0
                name='leftSide';
            end
                allVTAsAcounted=(VTA>0.5) & (heatmap.pmap>0);
                allUsedOriginVTAs=obj.(name).Map.*allVTAsAcounted;
                finalSum=sum(allUsedOriginVTAs,'all');
                sumOfValues=find(allVTAsAcounted);
                sumOfValues=numel(sumOfValues);
                obj.(name).average(1,counter)=finalSum/sumOfValues;
        end
    end
end

