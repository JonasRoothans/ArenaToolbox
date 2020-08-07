function  [v,f] = A_subdividesurface(obj,maxMaxEdgeAngle,maxVertices,maxConnections,buldgeFactor)

warning('off','all')
%nested functions:
    function edgeLengthHeap = computeEdgeLengths()
        edges = triangles.edges;
        edgeLengthHeap = zeros(size(edges,1),1);
        vertices = triangles.Points;
        for iEdge = 1:size(edges,1)
            thisEdge= edges(iEdge,:);
            vertex1 = vertices(thisEdge(1),:);
            vertex2 = vertices(thisEdge(2),:);
            edgelength = norm(vertex1-vertex2);
            edgeLengthHeap(iEdge) = edgelength;
        end
    end


    function edgeAngleHeap = computeEdgeAngles()
        edges = triangles.edges;
        edgeAngleHeap = zeros(size(edges,1),1);
        vertices = triangles.Points;
        for iEdge = 1:size(edges,1)
            thisEdge= edges(iEdge,:);
            connectedFaces = triangles.edgeAttachments(thisEdge);
            
            facenormal1 = triangles.faceNormal(connectedFaces{1}(1));
            facenormal2 = triangles.faceNormal(connectedFaces{1}(2));

            
            angle = abs(dot(facenormal1,facenormal2)/(norm(facenormal1)*norm(facenormal2)));

            edgeAngleHeap(iEdge) = angle;
        end
    end

    function ComputeMaxEdgeLength(edgeLengthHeap)
        [maxLength,idx]= max(edgeLengthHeap);
        maxLengthEdge = idx(1);
    end

    function ComputeMaxEdgeAngle(edgeAngleHeap)
        [maxAngle,idx]= max(edgeAngleHeap);
        maxAngleEdge = idx(1);
    end

    function [connectedTriangles,connectedTrianglesIdx] = getConnectedTriangles(edge)
        connectedTrianglesIdx = triangles.edgeAttachments(edge);
        connectedTrianglesIdx = sort(connectedTrianglesIdx{1},'descend');
        for triangleIdx = 1:numel(connectedTrianglesIdx)
            connectedTriangles{triangleIdx} = triangles.ConnectivityList(connectedTrianglesIdx(triangleIdx),:);
        end
        
    end

    function removeTriangle(idx)
        backupPoints = triangles.Points;
        backupConnectivityList = triangles.ConnectivityList;
        backupConnectivityList(idx,:) = []; %remove idx
        triangles = triangulation(backupConnectivityList,backupPoints);
    end

    function newPointIdx = addPoint(point)
        backupPoints = triangles.Points;
        backupConnectivityList = triangles.ConnectivityList;
        backupPoints(end+1,:) = point;
        newPointIdx = size(backupPoints,1);
        triangles = triangulation(backupConnectivityList,backupPoints);
    end

    function newTriangleIdx = addTriangle(newTriangle)
        backupPoints = triangles.Points;
        backupConnectivityList = triangles.ConnectivityList;
        backupConnectivityList(end+1,:) = newTriangle;
        newTriangleIdx = size(backupConnectivityList,1);
        triangles = triangulation(backupConnectivityList,backupPoints);
        
    end

    function neighbours = neighbourPoints(pointIdx)
        edges = triangles.edges;
        [edgenum,column] = find(edges==pointIdx);
        column(column==1) = 3;
        column(column==2) = 1;
        column(column==3) = 2;
        indices = sub2ind(size(edges),edgenum,column);
        
        neighbours = edges(indices);
    end







    function newPointIdx = splitEdgeIntoTwo(thisEdge)
        edges = triangles.edges;
        edgeInfo = edges(thisEdge,:);
        
        %compute mean vertex
        vertex1 = triangles.Points(edgeInfo(1),:);
        vertex2 = triangles.Points(edgeInfo(2),:);
        newpoint = mean([vertex1;vertex2]);
        newPointIdx = addPoint(newpoint);
        
        
        %get connected triangles
        [connectedTriangles,connectedTrianglesIdx] = getConnectedTriangles(edgeInfo); %returns: connectedTriangles and connectedTrianglesIdx
        
        %splitTwotriangles in half
        for iTriangle = 1:numel(connectedTrianglesIdx)
            idxTriangle = connectedTrianglesIdx(iTriangle);
            removeTriangle(idxTriangle)
            oldTriangle = connectedTriangles{iTriangle};
            
            %Split old triangle in triangleA and triangleB
            triangleA = oldTriangle;
            triangleA(triangleA==edgeInfo(1)) = newPointIdx;
            addTriangle(triangleA);
            
            
            triangleB = oldTriangle;
            triangleB(triangleB==edgeInfo(2)) = newPointIdx;
            addTriangle(triangleB);
            
        end
    end

    function normalbasedsmoothing(newPointIdx,neighbours,buldgeFactor)
        edges = triangles.edges;
        
        %         neighbours  = neighbourPoints(newPointIdx);
        %         neighbours = edges(maxLengthEdge,:);
        %         quadmiddle = mean([triangles.Points(edges(maxLengthEdge,1),:);triangles.Points(edges(maxLengthEdge,2),:)]);
        quadmiddle = triangles.Points(newPointIdx,:);
        
        d1 = 0.5*((triangles.Points(neighbours(1),:) - triangles.Points(neighbours(2),:))*triangles.vertexNormal(neighbours(1))');
        d2 = 0.5*((triangles.Points(neighbours(2),:) - triangles.Points(neighbours(1),:))*triangles.vertexNormal(neighbours(2))');
        
        E = quadmiddle+buldgeFactor*(d1*triangles.vertexNormal(neighbours(1))+d2*triangles.vertexNormal(neighbours(2)))/2;
        
        
        %apply modification
        backupPoints = triangles.Points;
        backupConnectivityList = triangles.ConnectivityList;
        backupPoints(newPointIdx,:) = E;%quadmiddle+buldgeFactor*displacementsum;
        triangles = triangulation(backupConnectivityList,backupPoints);
        
        
        
    end

    function goodcandidate = isgoodcandidate(thisEdge,maxConnections)
        edges = triangles.edges;
        edgeInfo = edges(thisEdge,:);
        
        
        %get connected triangles
        [connectedTriangles,~] = getConnectedTriangles(edgeInfo);
        involvedvertices = setdiff(unique(horzcat(connectedTriangles{:})),edgeInfo);
        connectedness = cellfun(@numel,triangles.vertexAttachments(involvedvertices'));
        goodcandidate = not(any(connectedness<maxConnections));
        
        
    end

    function [neighbours]  = adj(i)
        neighbours = neighbourPoints(i);
        
        
    end

    function p = improvedlaplaciansmoothing(triangles,varV)
        %based on http://informatikbuero.com/downloads/Improved_Laplacian_Smoothing_of_Noisy_Surface_Meshes.pdf
        % this algorithm simultaneously smooths variable points 
        alpha = 0;
        beta = 0.5;
        o = triangles.Points;
        p = o;
        repeat = 0;
        while repeat < 50
            disp(repeat);
            q = p;
            for i = 1:numel(varV)
                if ~varV(i);continue;end
           
                n = numel(adj(i));
                if n
                    p(i,:) = (1/n)*sum(q(adj(i),:)); %Laplacian operation
                end

                b(i,:) = p(i,:) - (alpha*o(i,:) + (1-alpha) * q(i,:));
            end
            for i = 1:numel(varV)
                if ~varV(i);continue;end
                n = numel(adj(i));
                if n
                    p(i,:) = p(i,:) - (beta*b(i,:) + (1-beta)/n * sum(b(adj(i),:)));
                end
            end
            repeat = repeat+1;
        end
        
           
        
        
    end





%% main function 

try
triangles = obj.gettriangulation;
catch
    error('This function requires the suresuiteSDK')
end

% edgeLengthHeap = computeEdgeLengths();
prevLength = Inf;
h = waitbar(0);

% set flag for vertices: 
variableVertices = zeros(size(triangles.Points,1),1); 
iterations  = 0;
maxIterations = 10;

maxAngle = Inf;

while maxAngle > maxMaxEdgeAngle && size(triangles.Points,1)<=maxVertices && iterations < maxIterations
    disp(iterations)
    
    edgeAngleHeap = computeEdgeAngles();
    ComputeMaxEdgeLength(edgeAngleHeap);
    newVertices = [];
    template = triangles;
    
    for iEdge = 1:size(template.edges,1)
        
        triangles = template;
        %only break edge when its too big.
        if edgeAngleHeap(iEdge) <= maxMaxEdgeAngle;
            continue;
        end
        
        edgeInfo = edges(iEdge,:);
        newPointIdx = splitEdgeIntoTwo(iEdge);
        
        %move new point
        normalbasedsmoothing(newPointIdx,edgeInfo,buldgeFactor)
        
        newVertices(end+1,:) = triangles.Points(newPointIdx,:);


    end
    
    %aggregate all points
    allvertices = [triangles.Points;newVertices];
    
    %define new convexhull
    triangles = triangulation(convhull(allvertices),allvertices);
    
    
    
    iterations = iterations+1;
end



close(h)


% set output variables
f = triangles.ConnectivityList;
v = triangles.Points;
end
