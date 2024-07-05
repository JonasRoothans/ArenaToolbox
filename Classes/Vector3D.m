classdef Vector3D
    %Vector3D contains x y and z, supports most vector functions
    
    properties
        x
        y
        z
        
    end
    
    properties (Hidden)
        description = '';
    end
    
    
    methods
        function obj = Vector3D(varargin)
            if nargin==4
                obj.x = double(varargin{1});
                obj.y = double(varargin{2});
                obj.z = double(varargin{3});
            end
            if nargin==3
                if all(cellfun(@isnumeric,varargin)) %if they are all numbers
                    obj.x = double(varargin{1});
                    obj.y = double(varargin{2});
                    obj.z = double(varargin{3});
                end
            elseif nargin==1
                if isnumeric(varargin{1})
                    obj.x = double(varargin{1}(1));
                    obj.y = double(varargin{1}(2));
                    obj.z = double(varargin{1}(3));
                end
                if isstruct(varargin{1})
                    if isfield(varargin{1},'x')
                        obj.x = varargin{1}.x;
                        obj.y = varargin{1}.y;
                        obj.z = varargin{1}.z;
                    end
                end
                if isa(varargin{1},'Vector3D')
                    obj.x = varargin{1}.x;
                    obj.y = varargin{1}.y;
                    obj.z = varargin{1}.z;
                end
            end
        end
        
        function out = unit(obj)
            if length(obj) ==1
                v = obj.getArray();
                l = norm(v);
                v = v/l;
                
                out = Vector3D(v);
            else
                out = obj;
                for i = 1:numel(obj)
                    v = obj(i).getArray();
                    l = norm(v);
                    v = v/l;
                    out(i).x = v(1);
                    out(i).y = v(2);
                    out(i).z = v(3);
                end
                
            end
            
        end
        
        function array = getArray(obj)
            array = [obj.x; obj.y; obj.z];
            if numel(obj)>1
                array = array';
            end
        end
        
        function length = norm(obj)
            v = obj.getArray();
            length = vecnorm(v');
        end
        
        %--Arena
        function [actor,scene] = see(obj,scenename)
            if nargin==1
                [actor,scene] = PointCloud(obj).see;
            elseif nargin==2
                [actor,scene] = PointCloud(obj).see(scenename);
            end
        end
        
        %--Booleans
        function bool = isempty(obj)
            bool = any([isempty(obj.x),...
                isempty(obj.y),...
                isempty(obj.z)]);
        end
        
        function bool = isnan(obj)
            bool = any([isnan(obj.x),...
                isnan(obj.y),...
                isnan(obj.z)]);
        end
        
        function bool = iszero(obj)
            bool = all(obj.getArray==0);
        end
        
        function bool = eq(o1,o2)
            bool = [];
            for iVector = 1:numel(o1)
                bool(iVector) = all(eq(o1(iVector).getArray,o2.getArray));
            end
            
        end
        
        
        function bool  = ne(o1,o2)
            bool = any(ne(o1.getArray,o2.getArray));
        end
        
        
        
        
        
        %---basic operations
        function out = plus(o1, o2)
            out = Vector3D(o1.getArray+o2.getArray);
        end
        
        function out = minus(o1,o2)
            if and(numel(o2)<numel(o1),or(numel(o2)==3,numel(o2)==1))
                if not(isa(o2,'Vector3D'));o2 = Vector3D(o2);end
                o2 =repmat(o2,numel(o1),1);
                difference = o1.getArray-o2.getArray;
                out  = PointCloud(difference).Vectors;
            else
                out = Vector3D(o1.getArray-o2.getArray);
            end
        end
        
        
        
        function out = mtimes(o1,o2)
            if isvector3d(o2)
                out = mtimes(o1.getArray',o2.getArray);
            elseif isnumeric(o2)
                out = Vector3D(o1.getArray*o2);
            end
        end
        
        function out = times(o1,o2)
            out = Vector3D(times(o1.getArray,o2.getArray));
        end
        
        function out = mrdivide(o1,o2)
            if isvector3d(o2)
                out = Vector3D(rdivide(o1.getArray,o2.getArray));
            elseif isnumeric(o2)
                out = Vector3D(o1.getArray/o2);
            end
        end
        
        function out = mean(o1,o2)
            outarray = mean([o1.getArray,o2.getArray]');
            out = Vector3D(outarray);
        end
        
        %-- vector operations
        
        function out = rotate(obj,x, y, z)
            
            Rx = [1 0 0; 0 cos(x) -sin(x); 0 sin(x) cos(x)];
            Ry = [cos(y) 0 sin(y); 0 1 0; -sin(y) 0 cos(y)];
            Rz = [cos(z) -sin(z) 0; sin(z) cos(z) 0; 0 0 1];
            
            R= Rx*Ry*Rz;
            R(4,4) = 1;
            out = obj.transform(R);
            
            
        end
        
        function out = lps2ras(o1)
            out = o1;
            out.x = -out.x;
            out.y = -out.y;
        end
        function out = ras2lps(o1)
            out = lps2ras(o1); %identical trick.
        end
        
        
        function out = cross(o1,o2)
            out = Vector3D(cross(o1.getArray,o2.getArray));
        end
        
        function out = transform(o1,T)
            if nargin==1
                error('Transformation matrix required')
            end
            if ~(round(T(1:3,4),5)==[0;0;0])
                if (round(T(4,1:3),5)==[0,0,0])
                    warning('T was probably transposed. This is automatically repaired.')
                    T = T';
                else
                    disp(T)
                    error ('Invalid transformation matrix.')
                end
            end
            
            % Add 1 to v3d
            if numel(o1)==1
                v3d = [o1.getArray',1];
            else
                v3d = [o1.getArray,ones(numel(o1),1)];
            end
            
            % Perform tranformation
            transformed = v3d*T;
            
            % create new Vector3D
            if numel(o1)==1
                out = Vector3D(transformed(1:3));
            else
                temp = PointCloud(transformed(:,1:3));
                out = temp.Vectors;
            end
            
        end
        
        function obj = legacy2MNI(obj)
            T = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
            obj = obj.transform(T);
        end
        
        function obj = stu2MNI(obj, anatomicalReference)
            Tapproved = load('Tapproved.mat');
            T = load('T2022.mat');
            Tfake2mni = [-1 0 0 0;0 -1 0 0;0 0 1 0;0 -37.5 0 1];
            
            %the idea is to first strip of the Tapproved to get the
            %registration to anatomy. (stu space)
            %and then apply the T2022
            switch anatomicalReference
                case 'yebstnleft' 
                    obj.transform(inv(Tapproved.mni2leftstn));
                    obj.transform(Tfake2mni);
                    obj.transform(T.stu2mni_leftSTN);
                case 'yebstnright'
                    %obj.transform(inv(Tapproved.rightstn2mni))
                    obj.transform(T.stu2mni_rightSTN);
                case 'yebgpileft' 
                    %obj.transform(inv(Tapproved.leftgpi2mni))
                    obj.transform(T.stu2mni_leftGPI);
                case 'yebgpiright' 
                    %obj.transform(inv(Tapproved.rightgpi2mni))
                    obj.transform(T.stu2mni_rightGPI);
            end
        end
        
        function rad = getAxiAngle(obj)
            rad = atan(obj.x/obj.y);
            if obj.y>0
                rad = rad+pi;
            end
        end
        
        
        
        function rad = getSagAngle(obj)
            rad = atan(obj.y/obj.z);
            if obj.z>0
                rad = rad+pi;
            end
        end
        
        
        
        function rad = getCorAngle(obj)
            rad = atan(obj.z/obj.x);
            if obj.x>0
                rad = rad+pi;
            end
        end
        
        
        function out = round(obj,N)
            if nargin==1
                out = Vector3D(round(obj.x),...
                    round(obj.y),...
                    round(obj.z));
            else
               out = Vector3D(round(obj.x,N),...
                    round(obj.y,N),...
                    round(obj.z,N));
            end
                
            
        end
        
        
        
    end
    
    methods(Static)
        %-- list operations
        function list = makelist(array)
            list = zeros(size(array,1),1);
            for i = 1:size(array,1)
                list(i) = Vector3D(array(i,:));
            end
        end
        
        function obj = setAxiAngle(rad)
            obj = Vector3D;
            obj.x = sin(rad);
            obj.y = cos(rad);
            obj.z = 0;
            
                
        end
        
        function obj = setSagAngle(rad)
            obj = Vector3D;
            obj.x = 0;
            obj.y = sin(rad);
            obj.z = cos(rad);
            
        end
        
        function obj = setCorAngle(rad)
            obj = Vector3D;
            obj.x = cos(rad);
            obj.y = 0;
            obj.z = sin(rad);
            
        end
        
        
    end
end
    
