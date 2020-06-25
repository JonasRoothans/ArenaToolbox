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
                    out(i) = v;
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
        function varargout = see(obj)
            varargout = PointCloud(obj).see;
        end
        
        %--Booleans
        function bool = isempty(obj)
            bool = any([isempty(obj.x),...
                isempty(obj.y),...
                isempty(obj.z)]);
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
        
        %-- vector operations
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
        
        
            
        
    end
    
     methods(Static)
%-- list operations
        function list = makelist(array)
            list = zeros(size(array,1),1);
            for i = 1:size(array,1)
                list(i) = Vector3D(array(i,:));
            end
        end
   end
end

