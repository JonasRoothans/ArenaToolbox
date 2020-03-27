function xyzn=meannorm_trismooth(xyz,t)

% Mean face normal filter for smoothing/denoising triangular meshes
%
% Reference:    1) Yagou, Belayev, Ohtake (2002) Mesh smoothing via Mean and
%               Median Filtering applied to face Normals, PGMP - Theory and
%               Applications
%               2) Zhang and Hamza, (2006) Vertex-based anisotropic smoothing of
%               3D mesh data, IEEE CCECE
% Acknowledgement:
%               Q. Fang: iso2mesh (http://iso2mesh.sf.net)
%
% Input:        xyz <nx3> vertex coordinates
%               t <mx3> triangulation index array
% Output:       xyzn <nx3> updated vertex coordinates
% Version:      1
% JOK 300709

% I/O check:
if nargin~=2
    error('Wrong # of input')
end
if nargout ~= 1
    error('Output is a single array, wrong designation!')
end
nt= size(t);
if nt(2)~=3
    error('Triangle element matrix should be mx3!')
end
mp = size(xyz);
if mp(2)~=3
    error('Vertices should be nx3!')
end

% Containing the elements adjacent to each vertex within t
[conn,connnum,count]=neighborelem(t,max(max(t)));% Triangles adjacent to each vertex;
trineigh = trineighborelem(t);% Containing each element adjacent to each elements
tarea = triangle_area(xyz,t);

% Initialize etc.
xyzn = zeros(size(xyz));
nvec = trinormal(t,xyz);
nvecn = zeros(size(nvec));
tol = 1e-2;err = Inf;
itermax = 30;iter = 0;
while err>tol && iter<itermax
    iter = iter+1;
    for k = 1:length(t)
        
        % Find triangles neighborhood
        indt01=trineigh{k}; % Element indices
        
        % Step 1: Area weighted face normal
        mti=1/sum(tarea(indt01))*sum(repmat(tarea(indt01),1,3).*nvec(indt01,:),1);
        
        % Step 2: Normalize mti & update
        lmti = sqrt(sum(mti.*mti,2));
        mti = mti./repmat(lmti,1,3);
        nvecn(k,:) = mti;
        
        % Step 3: update each vertex
        if length(indt01)>2
            for i = 1:3
                % Evaluate for each vertex in the central triangle: t(k,:)
                indvaux01 = t(k,i); % Current vertex
                indvaux02=conn{indvaux01};% Elements containing current vertex
                cj = tricentroid(xyz,t(indvaux02,:));
                nc=size(cj);
                eij =  cj-repmat(xyz(t(k,i),:),nc(1),1);
                pii = repmat(dot(eij,nvecn(indvaux02,:),2),1,3).*nvecn(indvaux02,:);
                xyzn(t(k,i),:)=xyz(t(k,i),:)+1/sum(tarea(indvaux02))*sum(repmat(tarea(indvaux02),1,3).*pii,1);
            end% for
        else
            xyzn(t(k,:),:) = xyzn(t(k,:),:);
        end% if
    end% for k
    tarean = triangle_area(xyzn,t);
    
    % Stopping criteria: face-normal error metric (L2-norm regardless of
    % median or mean filter used above)
    err = 1/sum(tarean)*sum(tarean.*sqrt(sum((nvec-nvecn).*(nvec-nvecn),2)),1);
    % Update coordinates, triangle normal vectors, mesh areas
    xyz = xyzn;
    nvec = nvecn;
    tarea=tarean;
    
end%while iter/err

end % meannormfilter_smooth_v01

% %%%%%%%%%%%%%%%%%%%%%% SUBFUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function [conn,connnum,count]=neighborelem(elem,nn)
% [conn,connnum,count]=neighborelem(elem,nn)
% neighborelem: create node neighbor list from a mesh
% parameters:
%    elem:  element table of a mesh
%    nn  :  total node number of the mesh
%    conn:  output, a cell structure of length nn, conn{n}
%           contains a list of all neighboring elem ID for node n
%    connnum: vector of length nn, denotes the neighbor number of each node
%    count: total neighbor numbers
conn=cell(nn,1);
dim=size(elem);
for i=1:dim(1)
  for j=1:dim(2)
    conn{elem(i,j)}=[conn{elem(i,j)},i];
  end
end
count=0;
connnum=zeros(1,nn);
for i=1:nn
    conn{i}=sort(conn{i});
    connnum(i)=length(conn{i});
    count=count+connnum(i);
end
end % neighborelem


%%
function [area]=triangle_area(xyz,t)
% This function gives the area of a triangle
aux1 = xyz(t(:,3),:)-xyz(t(:,1),:);
aux2 = xyz(t(:,2),:)-xyz(t(:,1),:);
aux3 = xyz(t(:,3),:)-xyz(t(:,2),:);
L = sort([sqrt(sum(aux1.*aux1,2)),sqrt(sum(aux2.*aux2,2)),sqrt(sum(aux3.*aux3,2))],2);

% Heron's formula (stable)
area= sqrt( (L(:,3)+(L(:,2)+L(:,1))).*(L(:,3)+(L(:,2)-L(:,1))).*(L(:,1)+(L(:,3)-L(:,2))).*(L(:,1)-(L(:,3)-L(:,2))) )./4; 
end % triangle_area

%%
function out = tricentroid(v,tri)
% Function to output the centroid of triangluar elements.
% Note that the output will be of length(tri)x3
% Input:    <v>     nx2 or 3: vertices referenced in tri
%           <tri>   mx3: triangle indices
% Version:      1
% JOK 300509

% I/O check
[nv,mv]=size(v);
[nt,mt]=size(tri);
if mv==2
    v(:,3) = zeros(nv,1);
elseif mt~=3
   tri=tri';
end

out(:,1) = 1/3*(v(tri(:,1),1)+v(tri(:,2),1)+v(tri(:,3),1));
out(:,2) = 1/3*(v(tri(:,1),2)+v(tri(:,2),2)+v(tri(:,3),2));
out(:,3) = 1/3*(v(tri(:,1),3)+v(tri(:,2),3)+v(tri(:,3),3));
end% tricentroid

%%
function trineigh=trineighborelem(elem)
% [conn,connnum,count]=neighborelem(elem,nn)
%
% neighborelem: create node neighbor list from a mesh
%
% author: fangq (fangq<at> nmr.mgh.harvard.edu)
% date: 2007/11/21
%
% parameters:
%    elem:  element table of a mesh
%    nn  :  total node number of the mesh
%    conn:  output, a cell structure of length nn, conn{n}
%           contains a list of all neighboring elem ID for node n
%    connnum: vector of length nn, denotes the neighbor number of each node
%    count: total neighbor numbers
%
% -- this function is part of iso2mesh toolbox (http://iso2mesh.sf.net)
%
nn = max(max(elem));
conn=cell(nn,1);
dim=size(elem);
for i=1:dim(1)
  for j=1:dim(2)
    conn{elem(i,j)}=[conn{elem(i,j)},i];
  end
end
count=0;
connnum=zeros(1,nn);
for i=1:nn
    conn{i}=sort(conn{i});
    connnum(i)=length(conn{i});
    count=count+connnum(i);
end

% Now identify all the nodes in one triangle and get them all into one
% array, so that all elements surrounding one element are listed
trineigh = cell(dim(1),1);
for i=1:dim(1)
    vind = elem(i,:); % Vertices for the i'th element
    aux01 = [conn{vind(1)},conn{vind(2)},conn{vind(3)}];
    aux02 = unique(aux01);
    trineigh{i} = aux02;
end
end%trineighborelem