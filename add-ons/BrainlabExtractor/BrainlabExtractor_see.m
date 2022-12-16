function [outputArg1,outputArg2] = BrainlabExtractor_see(menu,eventdata,scene,warpeddir)
%BRAINLABEXTRACTOR_SEE Summary of this function goes here
%   Detailed explanation goes here

if not(nargin==4)
    warpeddir = uigetdir();
end
    
actors = importWarped(warpeddir);
importLead(warpeddir)
detectLeadInVTAs()


    function actors = importWarped(diffdir)
        actors = ArenaActor.empty;
        files = A_getfiles(fullfile(diffdir,'*.nii'));
        for iFile = 1:numel(files)
            thisFile = files(iFile);
            if contains(thisFile.name,'lead')
                continue %those will be done in the next step
            end
            thisPath = fullfile(diffdir,thisFile.name);
            vd = VoxelData(thisPath);
            percent0 = total(round(vd)<=0)/numvox(vd)*100;
            if percent0>70
                vd.round()
                vd.Voxels(isnan(vd.Voxels)) =0;
                vd.Voxels(vd.Voxels<0) = 0;
                actors(end+1) = vd.getmesh(100).see(scene);
            else
                actors(end+1) = vd.getslice.see(scene);
            end
            
        end
    end

    function importLead(diffdir)
        files = A_getfiles(fullfile(diffdir,'mni_lead*.nii'));
        for iLead = 1:numel(files)/2
            
            tip = VoxelData(['mni_lead',num2str(iLead),'_tip.nii']).getmesh(100).getCOG;
            top = VoxelData(['mni_lead',num2str(iLead),'_top.nii']).getmesh(100).getCOG;
            direction = top-tip;
            e = Electrode(tip,direction.unit);
            e.see(scene)
        end
    end

    function detectLeadInVTAs()
        cogMesh = [];
        for iActor = 1:numel(actors)
            thisActor = actors(iActor);
            if isa(thisActor.Data,'Mesh')
                cogMesh(iActor,:) = thisActor.getCOG.getArray();
            end
        end
        

        for i = 1:size(cogMesh,1)
            for j = 1:size(cogMesh,1)
                if i==j
                    continue
                end
                if not(any(isnan(cogMesh([i,j],:))))
                    distance = sqrt(sum((cogMesh(i,:)-cogMesh(j,:)).^2))
                    if abs(distance-6)<1
                        e = Electrode;
                        if cogMesh(i,3)<cogMesh(j,3)
                            e.C0 = cogMesh(i,:);
                            e.PointOnLead(cogMesh(j,:));
                        else
                             e.C0 = cogMesh(j,:);
                            e.PointOnLead(cogMesh(i,:));
                        end
                        cogMesh(i,:) = [nan nan nan];
                        cogMesh(j,:) = [nan nan nan];
                        actor = e.see(scene);
                        actor.changeName('Automated electrode suggestion')
                    end
                end
            end
        end
        
    end



end

