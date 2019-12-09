classdef Slice < handle
    %Slice Level 1: Is obtained from voxeldata.
    
    properties
        Plane
        Settings
        Source
    end
    
    methods
        function obj = Slice(varargin)
            %MESH Construct an instance of this class
            %   Detailed explanation goes here
                if nargin==0
                    return
                end
                if isa(varargin{1},'VoxelData')
                    obj.Source = varargin{1};
                end
                if nargin==3
                    obj.getslicefromvoxeldata(varargin{2},varargin{3});
                    
                end
            end
        
        
        function obj = getslicefromvoxeldata(obj,varargin)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if iscell(varargin{1})
                varargin = varargin{1}; %get rid of double nesting
            end
            if numel(varargin)==0
                inplaneVector = Vector3D([0,0,0]);
                normalVector = Vector3D([0 0 1]);
            else
                inplaneVector = varargin{1};
                normalVector = varargin{2};
            end
              disp('Arena Slice: computing plane...')
             
              base = inplaneVector.getArray();
              
              w = null(normalVector.getArray()'); % Find two orthonormal vectors which are orthogonal to v
              [P,Q] = meshgrid(-50:50); % Provide a gridwork (you choose the size)
              X = base(1)+w(1,1)*P+w(1,2)*Q; % Compute the corresponding cartesian coordinates
              Y = base(2)+w(2,1)*P+w(2,2)*Q; %   using the two vectors in w
              Z = base(3)+w(3,1)*P+w(3,2)*Q;
              hslice = surf(X,Y,Z);
              xd = get(hslice,'XData');
              yd = get(hslice,'YData');
              zd = get(hslice,'ZData');
              delete(hslice)
              
              Plane.X = xd;
              Plane.Y = yd;
              Plane.Z = zd;
                obj.Plane = Plane;
            
             obj.Settings.baseVector = inplaneVector;
             obj.Settings.normalVector = normalVector;

            
              
        end
        
        
        function see(obj, sceneobj)
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
            thisScene.newActor(obj)
            
%             figure;
%             p= patch('Faces',obj.Faces,'Vertices',obj.Vertices);
%             
%             p.FaceColor = [0.3 0.6 0.8];
%             p.EdgeColor = 'none';
%             daspect([1 1 1])
%             view(3);
%             axis tight
%             camlight
%             lighting gouraud
        end
            
     
    end
end

