classdef Mesh < handle & matlab.mixin.Copyable & ArenaActorRendering
    %MESH Contains Faces and Vertices. Can be initialised with VoxelData
    
    properties
        Faces
        Vertices
        Settings
        Source
    end
    
    properties (Hidden)
        Label
    end
    
    methods
        function obj = Mesh(varargin)
            %MESH Construct an instance of this class
            %   Detailed explanation goes here
                if nargin==0
                    return
                end
                if isa(varargin{1},'VoxelData')
                    obj.getmeshfromvoxeldata(varargin);
                    obj.Source = varargin{1};
                %if isa(varargin{1}
                elseif isa(varargin{1},'double')
                        obj.Faces = varargin{1};
                        obj.Vertices = varargin{2};
                        obj.Source = [];
                        obj.Settings = [];
                end
            end
        
        
        function obj = getmeshfromvoxeldata(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            varargin = varargin{1}; %get rid of double nesting
            VoxelData_= varargin{1};
            if numel(varargin)==1
                T = obj.uithreshold(VoxelData_.Voxels);
            else
                T = varargin{2};
            end
            
            
            
            %increase resolution if resolution is bad, and only few voxels
            %will be visualized
            if VoxelData_.R.PixelExtentInWorldX>0.5 && sum(VoxelData_.Voxels(:)>T)< 70
                %interpolating
                Xo = VoxelData_.R.XWorldLimits(1)+VoxelData_.R.PixelExtentInWorldX/2:VoxelData_.R.PixelExtentInWorldX:VoxelData_.R.XWorldLimits(2);
                Yo = VoxelData_.R.YWorldLimits(1)+VoxelData_.R.PixelExtentInWorldY/2:VoxelData_.R.PixelExtentInWorldY:VoxelData_.R.YWorldLimits(2);
                Zo = VoxelData_.R.ZWorldLimits(1)+VoxelData_.R.PixelExtentInWorldZ/2:VoxelData_.R.PixelExtentInWorldZ:VoxelData_.R.ZWorldLimits(2);
                Xq = VoxelData_.R.XWorldLimits(1):0.5:VoxelData_.R.XWorldLimits(2);
                Yq = VoxelData_.R.YWorldLimits(1):0.5:VoxelData_.R.XWorldLimits(2);
                Zq = VoxelData_.R.ZWorldLimits(1):0.5:VoxelData_.R.XWorldLimits(2);
                
                [Xm,Ym,Zm] = meshgrid(Xo,Yo,Zo);
                [Xqq,Yqq,Zqq] = meshgrid(Xq,Yq,Zq);
                disp('Interpolating source data on 0.5mm grid')
                Vin = VoxelData_.Voxels;
                Vin(isnan(Vin)) = 0.0;
                try
                    Vq = interp3(Xm,Ym,Zm,Vin,Xqq,Yqq,Zqq,'nearest');
                    X = Xqq;
                    Y = Yqq;
                    Z = Zqq;
                    V  = Vq;
                catch
                    [X,Y,Z] = A_imref2meshgrid(VoxelData_.R);
                    V = VoxelData_.Voxels;
                end
                    
            else
                [X,Y,Z] = A_imref2meshgrid(VoxelData_.R);
                V = VoxelData_.Voxels;
            end
                
             disp('Arena Mesh: computing...')
%              test = VoxelData(V,VoxelData_.R);
%              test.getslice.see()
             [obj.Faces, obj.Vertices] = isosurface(X,Y,Z,V,T);
             obj.Settings.T = T;
        end
        
        
        
        function copyobj = duplicate(obj)
            copyobj = copy(obj);
        end
            
        function T = uithreshold(obj,Voxels)
            histf = figure;histogram(Voxels(:),50);  
            title({'Please place the vertical line at your preferred cut-off value.','This will define the look of the 3D shape'} )
            xlabel('Gray value (black --> white)');
            ylabel('Number of voxels with this value (log scale!')
            set(gca, 'YScale', 'log')
            try
                figure(histf)
                [T,~] = ginput(1);
            catch
                error('user canceled')

            end
            close(histf)
            
        end
        
        function newVD = convertToVoxelsInTemplate(obj,template)
                [gridX,gridY,gridZ] = template.getlinspace;
                fv.faces = obj.Faces;
                fv.vertices = obj.Vertices;
                
                minMesh = min(obj.Vertices);
                maxMesh = max(obj.Vertices);
                
                gridXtest = find(and(gridX>minMesh(1),gridX<maxMesh(1)));
                gridYtest = find(and(gridY>minMesh(2),gridY<maxMesh(2)));
                gridZtest = find(and(gridZ>minMesh(3),gridZ<maxMesh(3)));
                
                gridXvalues = gridX(gridXtest);
                gridYvalues = gridY(gridYtest);
                gridZvalues = gridZ(gridZtest);
                
                
                [testTheseX,testTheseY,testTheseZ] = meshgrid(gridXvalues,gridYvalues,gridZvalues);
                white = inpolyhedron(fv, [testTheseX(:),testTheseY(:),testTheseZ(:)],'flipnormals', false);
                
                newVoxelInfo = zeros(size(template.Voxels));
                newVoxelInfo(gridYtest,gridXtest,gridZtest) = reshape(white,size(testTheseX));
                
               
                
                
                newVD = VoxelData(newVoxelInfo,template.R);

        
                
                
        end
        
        
        
        function [thisActor,thisScene] = see(obj, sceneobj)
            global arena
            if nargin==1
                if isempty(arena)
                    evalin('base','startArena');
                    thisScene = arena.sceneselect(1);
                else
                    thisScene = arena.sceneselect();
                end
            else
                thisScene = sceneobj;
            end
            
            if isempty(thisScene);return;end %user cancels
            thisActor = thisScene.newActor(obj);
            if not(isempty(inputname(1)))
                thisActor.changeName(inputname(1))
            elseif not(isempty(obj.Label))
                thisActor.changeName(obj.Label)
            
                
            end
        end
        
        function cog = getCOG(obj)
            try
            cog = PointCloud(obj.Vertices).getCOG;
            catch
            cog = Vector3D([nan nan nan]);
            end
        end
        
        function mm = getCubicMM(obj)
            minrange = min(obj.Vertices); % can these values ever be positive? probably yes;
            minrange = ceil(abs(minrange)).*sign(minrange);
            maxrange = max(obj.Vertices);
            maxrange = ceil(abs(maxrange)).*sign(maxrange);

            


            x=minrange(1):0.25:maxrange(1)+1;
            y=minrange(2):0.25:maxrange(2)+1;
            z=minrange(3):0.25:maxrange(3)+1;

            [cubeX,cubeY,cubeZ] = meshgrid(x,y,z);
            points = PointCloud([cubeX(:),cubeY(:),cubeZ(:)]);
            %points.see
            overlap = obj.isInside(points);
            mm = sum(overlap)*0.25^3;          
            

        end
        
        function bool = isInside(obj,points)
            switch class(points)
                case 'PointCloud'
                    points = points.Vectors.getArray;

                case 'Vector3D'
                    points = points.getArray;
            end
            polyhedron.faces = obj.Faces;
            polyhedron.vertices = obj.Vertices;
            
            bool = inpolyhedron(polyhedron, points,'flipnormals', true);
           
  
        end
        
        function saveToFolder(obj,outdir,tag)
            %save obj, voxeldata and thresholded voxeldat
            if nargin==1
                [file,outdir] = uiputfile('*.obj');
                filepath = fullfile(outdir,file);
                tag = file(1:end-4);
            elseif nargin==2
                tag = newid;
                filepath = fullfile(outdir,[tag,'*.obj']);
            elseif nargin==3
                filepath = fullfile(outdir,[tag,'*.obj']);
            else
                return
            end
                
            %OBJ
            vertface2obj(obj.Vertices,obj.Faces,fullfile(outdir,[tag,'.obj']));
            
            %VoxelData
            try
            obj.Source.saveToFolder(outdir,tag);
           
                
            
            %Binary
            obj.Source.makeBinary(obj.Settings.T).saveToFolder(outdir,[tag,'_binary']);
             catch
                disp('Obj has no voxeldata')
            end
            
            
        end
            
     
    end
end

