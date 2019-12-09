classdef VoxelData <handle
    %VOXELDATA contains Voxels [3D array], R [imref], can load nii.
    %   Detailed explanation goes here
    
    properties
        Voxels
        R
    end
    
    
    methods
        function obj = VoxelData(varargin)
            %VOXELDATA Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==1
                if isfile(varargin{1})
                    obj = obj.loadnii(varargin{1});
                    
                end
            elseif nargin==2
                obj.Voxels = varargin{1};
                obj.R = varargin{2};
            end
        end
        
        function savenii(obj,filename)
            
            [x,y,z] = obj.R.worldToIntrinsic(0,0,0);
            spacing = [obj.R.PixelExtentInWorldX,obj.R.PixelExtentInWorldY,obj.R.PixelExtentInWorldZ];
            origin = [x y z]; 
            datatype = 8%64;
            nii = make_nii(permute(obj.Voxels,[2 1 3]), spacing, origin, datatype);
            save_nii(nii,filename)
        end
        
        function [obj,filename] = loadnii(obj,niifile)
            
            if nargin==1
                [filename,pathname] = uigetfile('*.nii','Find nii image');
                niifile = fullfile(pathname,filename);
            end
            if not(contains(niifile,'.nii'));error('input has to be a nifti file');end
            
            tempname = [datestr(datetime('now'),'yyyymmddhhMMss'),'.nii'];
            reslice_nii(niifile,fullfile(tempdir,tempname));
            reslicednifti = load_nii(fullfile(tempdir,tempname));
            delete(fullfile(tempdir,tempname));
            
            obj.Voxels = permute(reslicednifti.img,[2 1 3]);
            
            dimensions = reslicednifti.hdr.dime.dim(2:4);
            voxelsize = reslicednifti.hdr.dime.pixdim(2:4);
            transform = [reslicednifti.hdr.hist.srow_x;...
                reslicednifti.hdr.hist.srow_y;...
                reslicednifti.hdr.hist.srow_z;...
                0 0 0 1];
            
            
            
            % make imref
            Ref = imref3d(dimensions([2 1 3]),voxelsize(1),voxelsize(2),voxelsize(3));
            Ref.XWorldLimits = Ref.XWorldLimits+transform(1,4)-voxelsize(1);
            Ref.YWorldLimits = Ref.YWorldLimits+transform(2,4)-voxelsize(2);
            Ref.ZWorldLimits = Ref.ZWorldLimits+transform(3,4)-voxelsize(3);
            
            obj.R = Ref;
            
        end
        
        function showprojection(o1,view)
            [i,j,k] = o1.R.worldToIntrinsic(0,0,0);
            Origin_vxl = round([i,j,k]);
            if nargin == 1;view = 'a';end
            switch lower(view)
                case {'sagittal','s','sag'}
                    slice = squeeze(sum(o1.Voxels,2))';
                    origin_index = [2,3];
                case {'coronal','c','cor'}
                    slice = squeeze(sum(o1.Voxels,1))';
                    origin_index = [1,3];
                case {'axial','a','ax','axi'}
                    slice = sum(o1.Voxels,3);
                    origin_index = [1,2];
            end
            figure;imshow(slice/max(slice(:)));
            hold on
            scatter(Origin_vxl(origin_index(1)),Origin_vxl(origin_index(2)),'r','filled')
            ax = gca;
            ax.YDir = 'normal';
            
        end
        
        function showorigin(obj,view)
            [i,j,k] = obj.R.worldToIntrinsic(0,0,0);
            Origin_vxl = round([i,j,k]);
            if nargin == 1;view = 'a';end
            switch lower(view)
                case {'sagittal','s','sag'}
                    slice = squeeze(obj.Voxels(:,Origin_vxl(1),:))';
                    origin_index = [2,3];
                case {'coronal','c','cor'}
                    slice = squeeze(obj.Voxels(Origin_vxl(2),:,:))';
                    origin_index = [1,3];
                case {'axial','a','ax','axi'}
                    slice = obj.Voxels(:,:,Origin_vxl(3));
                    origin_index = [1,2];
            end
            figure;imshow(slice/max(slice(:)));
            hold on
            scatter(Origin_vxl(origin_index(1)),Origin_vxl(origin_index(2)),'r','filled')
            ax = gca;
            ax.YDir = 'normal';
        end
        
        function meshobj = getmesh(obj,T)
            if nargin==2
                meshobj = Mesh(obj,T);
            else
                meshobj = Mesh(obj);
            end
        end
        
        function sliceobj = getslice(obj,x,y,z)
            if nargin>1
                sliceobj = Slice(obj,x,y,z);
            else
                sliceobj = Slice(obj);
            end
        end
        
        function center_of_gravity = getcog(obj)
            
            
            [yq,xq,zq] = meshgrid(1:size(obj.Voxels,2),...
                1:size(obj.Voxels,1),...
                1:size(obj.Voxels,3));
            
            xm = xq(:)'*obj.Voxels(:) / sum(obj.Voxels(:));
            ym = yq(:)'*obj.Voxels(:) / sum(obj.Voxels(:));
            zm = zq(:)'*obj.Voxels(:) / sum(obj.Voxels(:));
         
            center_of_gravity_internal = [ym,xm,zm];
            [x,y,z] = obj.R.intrinsicToWorld(center_of_gravity_internal(1),center_of_gravity_internal(2),center_of_gravity_internal(3));
            center_of_gravity = Vector3D([x,y,z]);
            
        end
        
        function see(obj)
            disp('This funnction does not exist. Use [].getmesh.see instead')
        end
        
        function obj = warpto(obj,target,T)
            if nargin==2
                T = affine3d(eye(4));
            end
            
            obj.Voxels = imwarp(obj.Voxels,obj.R,T,'OutputView',target.R);
            obj.R = target.R;
        end
        function newObj = mirror(obj)
            if nargout==0
                error('output is required. Mirror makes a copy')
            end
   
            [imOut,rOut] = imwarp(obj.Voxels,obj.R,affine3d(diag([-1 1 1 1])));
            newObj = VoxelData(imOut,rOut);
            
        end
    end
end

