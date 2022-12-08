function [newactor] = A_addToVTApool(vta,scene)
%A_DEFINEVTA Summary of this function goes here
%   Detailed explanation goes here

[leadactor,name] = ArenaScene.getActorsOfClass(scene,'Electrode');
idx = listdlg('ListString',name,'PromptString','Select corresponding electrode:');

e = leadactor(idx);


%mattias space
Rvta = imref3d([61,61,85],[-7.625,7.625],[-7.625,7.625],[-7.625,13.625]);
offsetMiddle = -Rvta.PixelExtentInWorldX(1)/2;

coord = [...
    min(Rvta.XWorldLimits)-offsetMiddle    min(Rvta.YWorldLimits)-offsetMiddle   min(Rvta.ZWorldLimits)-offsetMiddle;
    max(Rvta.XWorldLimits)+offsetMiddle    min(Rvta.YWorldLimits)-offsetMiddle   min(Rvta.ZWorldLimits)-offsetMiddle;
    max(Rvta.XWorldLimits)+offsetMiddle    max(Rvta.YWorldLimits)+offsetMiddle   min(Rvta.ZWorldLimits)-offsetMiddle;
    min(Rvta.XWorldLimits)-offsetMiddle    max(Rvta.YWorldLimits)+offsetMiddle   min(Rvta.ZWorldLimits)-offsetMiddle;
    min(Rvta.XWorldLimits)-offsetMiddle    min(Rvta.YWorldLimits)-offsetMiddle   max(Rvta.ZWorldLimits)+offsetMiddle;
    max(Rvta.XWorldLimits)+offsetMiddle    min(Rvta.YWorldLimits)-offsetMiddle   max(Rvta.ZWorldLimits)+offsetMiddle;
    max(Rvta.XWorldLimits)+offsetMiddle    max(Rvta.YWorldLimits)+offsetMiddle   max(Rvta.ZWorldLimits)+offsetMiddle;
    min(Rvta.XWorldLimits)-offsetMiddle    max(Rvta.YWorldLimits)+offsetMiddle   max(Rvta.ZWorldLimits)+offsetMiddle;];
idx = [4 8 5 1 4; 1 5 6 2 1; 2 6 7 3 2; 3 7 8 4 3; 5 8 7 6 5; 1 4 3 2 1]';


xc = coord(:,1);
yc = coord(:,2);
zc = coord(:,3);

[box,actor] = Shape(xc(idx), yc(idx), zc(idx),scene);

ez = e.Data.Direction.unit;
ex = cross(Vector3D([sin(rad2deg(e.Data.Roll)), cos(rad2deg(e.Data.Roll)), 0]),ez);
ey = cross(ez,ex);


C0 = e.Data.C0;

T = [ex.unit.getArray',0;
    ey.unit.getArray',0;
    ez.unit.getArray',0;
    C0.x C0.y C0.z 1];


Ti = round(inv(T),5);

actor.transform(scene,'T',T)
vta.transform(scene,'T',Ti);
e.transform(scene,'T',Ti);

canvas = nan([61,61,85]);


%preparing initial seed points
[canvasx,canvasy,canvasz] = Rvta.worldToSubscript(vta.Data.Vertices(:,1),vta.Data.Vertices(:,2),vta.Data.Vertices(:,3));
c = [canvasx,canvasy,canvasz];
toTest = unique(c,'rows');

neighbourmatrix = [...
    1 1 1;
    1 1 -1;
    1 -1 1;
    1 -1 -1;
    -1 1 1;
    -1 1 -1;
    -1 -1 1;
    -1 -1 -1];

f = figure;

while not(isempty(toTest))
   testLater = [];
    
    [x,y,z] = Rvta.intrinsicToWorld(toTest(:,1),toTest(:,2),toTest(:,3));
    inmeshlist = vta.Data.isInside([x,y,z]);
    
    for i = 1:numel(inmeshlist)
        this = [toTest(i,1),toTest(i,2),toTest(i,3)];
        if inmeshlist(i)
            canvas(this(1),this(2),this(3)) = 1;
            %get neighbours
            neighbours = this + neighbourmatrix;
            for j = 1:8
                    testLater(end+1,:) = neighbours(j,:);
            end
        
        else
            canvas(this(1),this(2),this(3)) = 0;
        end
    end
    
    %--- overwrite toTest
    toTest = unique(testLater,'row');
    
    %-- filter
    remove = [];
    for i = 1:size(toTest,1)
        this = [toTest(i,1),toTest(i,2),toTest(i,3)];
        if not(isnan(canvas(this(1),this(2),this(3))))
            remove(i) = 1;
        else
            remove(i) = 0;
        end
    end
    toTest(remove>0.5,:) = [];
    figure(f);
      imagesc(nansum(permute(canvas,[2,3,1]),3))
      drawnow()

end


canvas(isnan(canvas)) = 0;
 vd = VoxelData(canvas,Rvta);
 newactor = vd.getmesh(0.5).see(scene);
 
 vta.transform(scene,'T',T);
 e.transform(scene,'T',T)
 newactor.transform(scene,'T',T)
actor.delete()
 

Done;

