function xyzn=lpflow_trismooth(xyz,t)
% Laplace flow mesh smoothing for vertex ring
% 
% Reference:    1) Zhang and Hamza, (2006) Vertex-based anisotropic smoothing of
%               3D mesh data, IEEE CCECE
% Acknowledgement:
%               Q. Fang: iso2mesh (http://iso2mesh.sf.net)
%
% Input:        xyz <nx3> vertex coordinates
%               t <mx3> triangulation index array
% Output:       xyzn <nx3> updates vertex coordinates
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

% Initialize etc.
k=0;
[conn,connnum,count]=neighborelem(t,max(max(t)));
xyzn = xyz;
while k<length(xyz)
    k=k+1;
    % Find vertex neighborhood
    indt01=conn{k}; % Element indices
    indv01 = t(indt01,:);
    indv01 = unique(indv01(:));
    vdist = xyz(indv01,:)-repmat(xyz(k,:),length(indv01),1);
    dist = sqrt(sum(vdist.*vdist,2));
    indaux1 = find(dist==0);
    vdist(indaux1,:) =[];
    d=length(vdist); % Cardinality of vertex
    if isempty(dist)
        xyzn(k,:)  = NaN;
    end
    vcorr = sum(vdist/d,1);
    xyzn(k,:) = xyz(k,:)+vcorr;
end

end % lpflow_smooth_v01

%%
function [conn,connnum,count]=neighborelem(elem,nn)
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