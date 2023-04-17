classdef VoxelDataStackExtended < VoxelDataStack
    %VOXELDATASTACKEXTENDED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Voxels2
        VoxelLabels = {'primary','secundary'}
    end
    
    methods
        function obj = VoxelDataStackExtended(Voxels,R,Weights, Voxels2)
            
            if nargin>0
                %serialize
                if length(size(Voxels))>2
                    obj.Voxels = reshape(single(Voxels),[],size(Voxels,4)); %by default to minimize memory consumption
                else
                    if not(issparse(Voxels))
                        obj.Voxels = single(Voxels);
                    else
                        obj.Voxels = Voxels; %sparse does not support single
                    end
                end
            end
            if nargin>1
                obj.R = R;
            end
            if nargin>2
                obj.Weights = Weights;
            end

            if nargin==4 % costract the possibility of flipping

                %serialize
                if length(size(Voxels2))>2
                    obj.Voxels = reshape(single(Voxels2),[],size(Voxels2,4)); %by default to minimize memory consumption
                else
                    if not(issparse(Voxels2))
                        obj.Voxels2 = single(Voxels2);
                    else
                        obj.Voxels2 = Voxels2; %sparse does not support single
                    end
                end
            end

        end
        
        function obj = addNiiWithScore(obj,niiPath,score,niiPath2) % i changed that, so that it adds the fliped things
            
            if ischar(niiPath)
                VD = VoxelData(niiPath);
            elseif isa(niiPath,'VoxelData')
                VD=niiPath;
            else 
                error('  "Mother of Got" (T.S)...your argument must be a path to nii or a VoxelData...people use your brains')
            end

            [~,j] = size(obj.Voxels);
            
            if j == 0
                obj.R = VD.R;
            else
                VD.warpto(obj);
            end
            obj.Voxels(:,j+1) = VD.Voxels(:);
            obj.Weights(j+1) = score;

            if nargin == 4
                if ischar(niiPath2)
                Voxels2VD = VoxelData(niiPath2);
                elseif isa(niiPath2,'VoxelData')
                    Voxels2VD = niiPath2;
                else 
                    error (' "Mother of Got" (T.S) ...your argument must be a path to nii or a VoxelData...people use your brains')
                end

                if j>0
                Voxels2VD.warpto(obj);
                end

                obj.Voxels2(:,j+1) = Voxels2VD.Voxels(:);
            end
        end
    end
end

