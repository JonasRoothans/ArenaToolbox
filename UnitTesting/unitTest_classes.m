classes = {'ArenaScene',...
    'ArenaManager',...
    'ArenaActor',...
    'VoxelData',...
    'Mesh',...
    'Slice',...
    'ObjFile',...
    'VectorCloud',...
    'PointCloud',...
    'Vector3D'};


%% test empty initialization
for iClass = 1:numel(classes)
    thisClass = classes{iClass};
    
    switch thisClass
        case 'ArenaManager';continue %initiates window
        otherwise
            eval([thisClass,';'])
    end
end


    
