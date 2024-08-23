function [outputArg1,outputArg2] = Noodles_runbasic(menu,eventdata,scene)
%NOODLES_RUNBASIC() Summary of this function goes here
%   Detailed explanation goes here

if 0
    fibers = {};
    cohort1 = {};
    cohort2 = {};
    
    load('NoodlesConfig')
    %Load Fibers
    for iFiber = 1:numel(NoodlesConfig.fibers)
        f = Fibers();
        
        [~,~, ext] = fileparts(NoodlesConfig.fibers{iFiber});
        switch ext
            case '.vtk'
                fname = fullfile(NoodlesConfig.fibersfolder,NoodlesConfig.fibers{iFiber});
                f.loadvtk(fname)
            otherwise
                error('Fiber file extension not yet supported.')
        end
        fibers{iFiber}=f;
    end
    
    %Load Cohort 1
    files_c1 = A_getfiles(fullfile(NoodlesConfig.Cohort1,'*.nii'));
    for ic1 = 1:numel(files_c1)
        fname = fullfile(files_c1(ic1).folder,files_c1(ic1).name);
        vd = VoxelData;
        vd.loadnii(fname)
        cohort1{ic1} = vd;
    end
    
    %Load Cohort 2
    files_c2 = A_getfiles(fullfile(NoodlesConfig.Cohort2,'*.nii'));
    for ic2 = 1:numel(files_c2)
        fname = fullfile(files_c2(ic2).folder,files_c2(ic2).name);
        vd = VoxelData;
        vd.loadnii(fname)
        cohort2{ic2} = vd;
    end
    
    
end
%%

fiber = struct();

for iFiberFile = 1:numel(fibers)
    disp([num2str(iFiberFile),'/',num2str(numel(fibers))])
    thisFiberFile = fibers{iFiberFile};
    
    disp('serializing..')
    [allFiberVertices,indcs] = thisFiberFile.serialize();

    
    disp('checking points in Efields...')
        for iCohort1 = 1:numel(cohort1)
            thisCohort1 = cohort1{iCohort1};
            values = thisCohort1.getValueAt(allFiberVertices);
            for iFiberLine = 1:numel(indcs)-1
                fiber(iFiberFile).cohort(1).line(iFiberLine,iCohort1) = nanmax(values(indcs(iFiberLine):indcs(iFiberLine+1)-1));
            end
        end
        
        
        for iCohort2 = 1:numel(cohort2)
            thisCohort2 = cohort1{iCohort2};
            values = thisCohort2.getValueAt(allFiberVertices);
            for iFiberLine = 1:numel(indcs)-1
                fiber(iFiberFile).cohort(2).line(iFiberLine,iCohort2) = nanmax(values(indcs(iFiberLine):indcs(iFiberLine+1)-1));
            end
        end
        
        
end

%statistics


for iFiber = 1:numel(fiber)
    weights = [];
    for iLine = 1:numel(fibers{iFiber}.Vertices)
        [h,p,ci,stat] = ttest2(fiber(iFiber).cohort(1).line(iLine,:),fiber(1).cohort(2).line(iLine,:));
        t = stat.tstat;
        weights(iLine) = t;
    end
    fibers{iFiber}.Weight = weights;
    fibers{iFiber}.see(scene)
end

end

