function [outputArg1,outputArg2] = BrainlabExtractor_newNative(menu,eventdata,scene)
% 
mainPath = fileparts(mfilename('fullpath'));
referencePath = fullfile(mainPath,'RefAnatomy'); %reference anatomy
warpPath = fullfile(mainPath,'Warp');  %for saving transformation matrix

%ask for input structure
waitfor(msgbox('Find the NATIVE atlas file'))
[filename,pathname] = uigetfile('*','Get the folder with nii files');

%load input
[native_V, native_F] = load_obj(fullfile(pathname,filename));

%ask description of input
options = {'STN left','STN right','GPi left','GPi right'};
[indx] = listdlg('PromptString',{['What is ',filename,'?']},...
    'SelectionMode','single','ListString',...
    options);
anatomy = options{indx};

%load MNI reference
references = {'STN left.obj','STN right.obj','GPi left.obj','GPi right.obj'};
reference = fullfile(referencePath,references{indx});
[norm_V, ~] = load_obj(reference);

%ask for name
pathcell = strsplit(mainPath,filesep);
name_suggestion = [anatomy,'___',pathcell{end}, '_',filename(1:end-4)];
name = newid({'Save this warp as: '},'Arena',1,{name_suggestion});

%Algorithm----
[native_V, ~] = keep_largest_face_component(native_V, native_F);
norm_pca = compute_pca_landmarks(norm_V);       
native_pca = compute_pca_landmarks(native_V); 
[R, t, s] = compute_similarity_transform(norm_pca, native_pca);
T = eye(4);
T(1:3,1:3) = R*eye(3)*s;
T(1:3,4) = t;
T = T';
%-------------
    
%Save 
save(fullfile(warpPath,['Norm2Native_',name{1},'.mat']),'T')
T = inv(T);
save(fullfile(warpPath,['Native2Norm_',name{1},'.mat']),'T')
BrainlabExtractor_updateNativeMenu(menu,eventdata,scene)
Done;


function [V, F] = load_obj(filename)
    % Basic OBJ loader for vertices and faces
    % Only supports 'v' and 'f' lines of a simple OBJ.
    
    fid = fopen(filename,'r');
    if fid < 0
        error('Cannot open file: %s', filename);
    end
    
    V = [];
    F = [];
    while ~feof(fid)
        line = fgetl(fid);
        if ~ischar(line), break; end
        
        tokens = strsplit(strtrim(line));
        if isempty(tokens)
            continue;
        end
        
        switch tokens{1}
            case 'v'
                % vertex line: v x y z
                v = str2double(tokens(2:4));
                V = [V; v];
            case 'f'
                % face line: f idx1 idx2 idx3 ...
                % assuming triangular faces
                f = tokens(2:end);
                f = cellfun(@(x) sscanf(x, '%d//%d'), f,'UniformOutput',false);
                % Some OBJ have 'f v//vn' or 'f v/vt/vn' formats. 
                % Simplify: take first integer of each.
                f = cellfun(@(x) x(1), f);
                F = [F; f(:)'];
        end
    end
    fclose(fid);
end

function A = compute_pca_landmarks(points)
    com = mean(points,1);
    [coeff,score,~] = pca(points);
    mins = min(score);
    maxs = max(score);

    A = com;
    for i = 1:3
        min_pt = com + mins(i)*coeff(:,i)';
        max_pt = com + maxs(i)*coeff(:,i)';
        A = [A; min_pt; max_pt];
    end
end

function [R, t, s] = compute_similarity_transform(A, B)
    centroid_A = mean(A,1);
    centroid_B = mean(B,1);

    AA = A - centroid_A;
    BB = B - centroid_B;

    norm_A = sqrt(sum(AA.^2,2));
    norm_B = sqrt(sum(BB.^2,2));

    if mean(norm_A) < 1e-10
        s = 1.0;
    else
        s = mean(norm_B)/mean(norm_A);
    end

    AA_scaled = AA * s;
    H = AA_scaled' * BB;
    [U,~,V] = svd(H);
    R = V*U';
    if det(R)<0
        V(:,end) = -V(:,end);
        R = V*U';
    end

    t = centroid_B' - R*(centroid_A'*s);
end

function [Vout, Fout] = keep_largest_face_component(V, F)
    
    numFaces = size(F,1);
    facesForVertex = cell(size(V,1), 1);

    for fi = 1:numFaces
        for v = F(fi,:)
            facesForVertex{v} = [facesForVertex{v}, fi];
        end
    end

    faceAdj = cell(numFaces,1);
    for fi = 1:numFaces
        verts = F(fi,:);
        connectedFaces = [];
        for v = verts
            connectedFaces = [connectedFaces, facesForVertex{v}];
        end
        connectedFaces = unique(connectedFaces);
        connectedFaces(connectedFaces==fi) = [];
        faceAdj{fi} = connectedFaces;
    end

    visited = false(numFaces,1);
    faceLabel = zeros(numFaces,1);
    ccIndex = 0;

    for fi = 1:numFaces
        if ~visited(fi)
            ccIndex = ccIndex + 1;
            stack = fi;
            while ~isempty(stack)
                top = stack(end);
                stack(end) = [];
                if ~visited(top)
                    visited(top) = true;
                    faceLabel(top) = ccIndex;
                    stack = [stack, faceAdj{top}];
                end
            end
        end
    end

    ccs = unique(faceLabel);
    faceCounts = arrayfun(@(c) sum(faceLabel == c), ccs);
    [~, largestIdx] = max(faceCounts);
    largestComponent = ccs(largestIdx);

    mask = (faceLabel == largestComponent);
    Fout = F(mask, :);

    usedVerts = unique(Fout(:));
    newMap = zeros(size(V,1),1);
    newMap(usedVerts) = 1:numel(usedVerts);

    Vout = V(usedVerts, :);
    Fout = newMap(Fout);
end




end

