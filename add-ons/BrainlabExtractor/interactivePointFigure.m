function fig = interactivePointFigure(vd,e)
% Create a figure and axes
fig = figure;
ax = axes('Parent', fig);
axis off
hold on;

% Initialize variables
isButtonPressed = false;
closestPointIndex = 0;
previousPoint = 0;
mouseIsLeft = 1;

%make cross-section
ImCor = [];
ImSag = [];
vxl = 0.25;
updateSlice()

p = plotPatch();
p_init = {p.Vertices};
updatePatch



%create electrodes and append the transormationmatrix

scaling = 1/vxl;
delta = 1; % Distance from the central line
drawDepth = 0;
deltaDepth = 8*scaling;
depthLineLength = 12*scaling;
tipoffset = 1*scaling;
Ecor = drawElectrode(ImCor.LeadPos); %x coordinate
Esag = drawElectrode(ImSag.LeadPos);
Ecor.T = ImCor.T;
Esag.T = ImSag.T;
Ecor.Tintrinsic = ImCor.Tintrinsic;
Esag.Tintrinsic = ImSag.Tintrinsic;



% Set up mouse callback functions
set(fig, 'WindowButtonDownFcn', @mouseDownCallback);
set(fig, 'WindowButtonUpFcn', @mouseUpCallback);
set(fig, 'KeyPressFcn', @(src, event) closeFigureOnEnter(src, event))


% Mouse down callback function

% Set aspect ratio to be equal
axis equal;

set(fig, 'WindowState', 'maximized');

    function handles = drawElectrode(leadpos)
        x = leadpos(1);
        y = leadpos(2);
        % Set up initial point positions
        initialPositions = [x, y; x, y+20*scaling];
        
        % Create point scatter plots
        numPoints = size(initialPositions, 1);
        points = gobjects(numPoints, 1);
        for i = 1:numPoints
            points(i) = scatter(ax, initialPositions(i, 1), initialPositions(i, 2), 'ro', 'MarkerFaceColor', 'none');
        end
        
        % Create initial line between the two points
        handles.lineObj = line(ax, initialPositions(:, 1), initialPositions(:, 2), 'Color', 'k', 'LineStyle', '-');
        
        % Calculate the direction vector of the central line
        directionVector = [points(2).XData - points(1).XData, points(2).YData - points(1).YData];
        
        % Calculate the perpendicular direction vector
        perpendicularVector = [-directionVector(2), directionVector(1)];
        
        % Calculate the parallel lines coordinates
        
        parallelLine1XCoordinates = [points(1).XData + delta*scaling, points(2).XData + delta*scaling];
        parallelLine1YCoordinates = [points(1).YData, points(2).YData];
        parallelLine2XCoordinates = [points(1).XData - delta*scaling, points(2).XData - delta*scaling];
        parallelLine2YCoordinates = [points(1).YData, points(2).YData];
        
        % Create parallel lines
        handles.parallelLine1 = line(ax, parallelLine1XCoordinates, parallelLine1YCoordinates, 'Color', 'r', 'LineStyle', '-');
        handles.parallelLine2 = line(ax, parallelLine2XCoordinates, parallelLine2YCoordinates, 'Color', 'r', 'LineStyle', '-');
        
        
        if drawDepth
        % Set the initial position of the depth line
        [~, lowestPoint ]= min([points(1).YData, points(2).YData]);
        centerDepthLine = [points(lowestPoint).XData,points(lowestPoint).YData];
        
        depthLineXCoordinates = centerDepthLine(1)+[-5 5];
        depthLineYCoordinates = centerDepthLine(2)-[tipoffset tipoffset]*scaling;
        
        % Initialize the depth line
        handles.depthLine = line(ax, depthLineXCoordinates, depthLineYCoordinates, 'Color', 'r', 'LineStyle', '-');
        end
        handles.points = points;
    end

    function mouseDownCallback(~, ~)
        currentPoint = ax.CurrentPoint(1, 1:2);
        [points,~] = getPointsAndHandles();
        distances = vecnorm(getPointPositions() - currentPoint, 2, 2);
        [~, closestPointIndex] = min(distances);
        previousPoint = currentPoint;
        isButtonPressed = true;
        
        % Fill the closest point
        set(points(closestPointIndex), 'MarkerFaceColor', 'r');
    end

    function [points,handles] = getPointsAndHandles()
        %update the Electrode structures with imaging structures
        Ecor.T = ImCor.T;
        Esag.T = ImSag.T;
        Ecor.Tintrinsic = ImCor.Tintrinsic;
        Esag.Tintrinsic = ImSag.Tintrinsic;
        
        currentPoint = ax.CurrentPoint(1, 1:2);
        if currentPoint(1)<(50*scaling)+1
            points = Ecor.points;
            handles = Ecor;
            disp('Cor')
        else
            points = Esag.points;
            handles = Esag;
            disp('Sag')
        end
    end

% Mouse up callback function
    function mouseUpCallback(~, ~)
        isButtonPressed = false;
        [points,handles] = getPointsAndHandles();

        
        % Reset the closest point
        set(points(closestPointIndex), 'MarkerFaceColor', 'none');
        
        %calculate the distance between points:
        allPoints = [points(1).XData,points(1).YData;points(2).XData,points(2).YData];
        distance = sqrt(sum(diff(allPoints).^2));
        
        %new image
        allPoints(:,[3,4])= [0,1;0,1];
        allPointsWorld = allPoints*handles.T;
        disp(allPointsWorld)
        [~, lowestPointIndex] = min(allPointsWorld(:,3));
        
        e.C0 = allPointsWorld(lowestPointIndex,[1 2 3]);
        e.PointOnLead(allPointsWorld(3-lowestPointIndex,[1 2 3]))
        

        updateSlice()
        
        
        %reset
        Ecor.points(1).XData = ImCor.LeadPos(1);
        Ecor.points(1).YData = ImCor.LeadPos(2);
        Ecor.points(2).XData = ImCor.LeadPos(1);
        Ecor.points(2).YData = ImCor.LeadPos(2)+distance;
        
        Esag.points(1).XData= ImSag.LeadPos(1);
        Esag.points(1).YData = ImSag.LeadPos(2);
        Esag.points(2).XData = ImSag.LeadPos(1);
        Esag.points(2).YData = ImSag.LeadPos(2)+distance;
        
        mouseMoveCallback()
        
    end

% Mouse move callback function
    function mouseMoveCallback(~, ~)

            if ax.CurrentPoint(1,1)<(50*scaling+1)
                points = Ecor.points;
                handles = Ecor;
                if ~mouseIsLeft
                    resetPatch
                    mouseIsLeft = 1;
                end
                
            else
                points = Esag.points;
                handles = Esag;
                if mouseIsLeft
                    resetPatch
                    mouseIsLeft = 0;
                end
            end
            if isButtonPressed
                currentPoint = ax.CurrentPoint(1, 1:2);
                %-- move lead
                if norm([points(1).XData - currentPoint(1), points(1).YData - currentPoint(2)]) > 4*scaling && ...
                        norm([points(2).XData - currentPoint(1), points(2).YData - currentPoint(2)]) > 4*scaling
                    delta = currentPoint - previousPoint; % Calculate the change in cursor position
                    points(1).XData = points(1).XData + delta(1);
                    points(1).YData = points(1).YData + delta(2);
                    points(2).XData = points(2).XData + delta(1);
                    points(2).YData = points(2).YData + delta(2);
                    
               %--- rotate lead
                else
                    points(closestPointIndex).XData = currentPoint(1);
                    points(closestPointIndex).YData = currentPoint(2);
                end
                
                %Transform Coronal
                T = eye(3);
                
                updatePatch(handles)
                
            else
                % Check distance to fill/reset the point
                currentPoint = ax.CurrentPoint(1, 1:2);
                distances = vecnorm(getPointPositions() - currentPoint, 2, 2);
                [minDistance, closestPointIndex] = min(distances);
                if minDistance <=2*scaling
                    set(points(closestPointIndex), 'MarkerFaceColor', 'r');
                else
                    set(points(closestPointIndex), 'MarkerFaceColor', 'none');
                end
            end
            
            % Update the line between the two points
            handles.lineObj.XData = [points(1).XData, points(2).XData];
            handles.lineObj.YData = [points(1).YData, points(2).YData];
            
            % Update the parallel lines
            delta = 1*scaling;
            dx = points(2).XData - points(1).XData;
            dy = points(2).YData - points(1).YData;
            normFactor = sqrt(dx^2 + dy^2);
            dxNorm = dx / normFactor;
            dyNorm = dy / normFactor;
            
            handles.parallelLine1.XData = [points(1).XData + delta * dyNorm, points(2).XData + delta * dyNorm];
            handles.parallelLine1.YData = [points(1).YData - delta * dxNorm, points(2).YData - delta * dxNorm];
            
            handles.parallelLine2.XData = [points(1).XData - delta * dyNorm, points(2).XData - delta * dyNorm];
            handles.parallelLine2.YData = [points(1).YData + delta * dxNorm, points(2).YData + delta * dxNorm];
            
            % Update the depth line position when dragging the points
            updateDepthLine(handles);
            
            
            
            % Store the current cursor position for the next iteration
            previousPoint = currentPoint;
    end


% Function to get the current positions of the points
    function positions = getPointPositions()
            if ax.CurrentPoint(1, 1)<(50*scaling+1)
                points = Ecor.points;
            else 
                points = Esag.points;
            end
            for i = 1:2
                positions(i, 1) = points(i).XData;
                positions(i, 2) = points(i).YData;
            end
    end

% Function to update the position of the depth line
    function updateDepthLine(handles)
        if drawDepth
        points = handles.points;
        % Find the index of the lowest point
        [~, lowestPointIndex] = min([points(1).YData, points(2).YData]);
        
        % Get the coordinates of the lowest point
        lowestPointX = points(lowestPointIndex).XData;
        lowestPointY = points(lowestPointIndex).YData;
        
        % Calculate the direction vector of the line between the points
        directionVector = [points(2).XData - points(1).XData, points(2).YData - points(1).YData];
        
        % Calculate the perpendicular direction vector
        perpendicularVector = [-directionVector(2), directionVector(1)];
        perpendicularVector = perpendicularVector / norm(perpendicularVector); % Normalize the perpendicular vector
        
        % Calculate the coordinates of the depth line
        
        depthLineStart = [lowestPointX - 0.5 * depthLineLength * perpendicularVector(1), lowestPointY - 0.5 * depthLineLength * perpendicularVector(2)];
        depthLineEnd = [lowestPointX + 0.5 * depthLineLength * perpendicularVector(1), lowestPointY + 0.5 * depthLineLength * perpendicularVector(2)];
        
        % Update the position of the depth line
        set(handles.depthLine, 'XData', [depthLineStart(1), depthLineEnd(1)], 'YData', [depthLineStart(2), depthLineEnd(2)]);
        end
    end

    function updateSlice()
        
        % Extract the 2D slice within the bounding box
        [backgroundImageCor,Tcor,TintrinsicCor] = A_obliquesliceParallelToElectrode(vd,e, 'cor',vxl);
        [backgroundImageSag,Tsag,TintrinsicSag] = A_obliquesliceParallelToElectrode(vd,e, 'sag',vxl);
        
        %correction for sticking the figures next to each other
        TjoinCorrection = eye(4);
        TjoinCorrection(4,1) = -size(backgroundImageSag,1);
        
        
        
            ImCor.T = Tcor;
            ImSag.T = TjoinCorrection*Tsag;
            ImCor.LeadPos = abs(TintrinsicCor(4,[1,3]))/vxl;
            ImSag.LeadPos = (abs(TintrinsicSag(4,[2,3]))/vxl+[size(backgroundImageCor,1),0]); %last term corrects for joining the figures.
            ImCor.Tintrinsic = TintrinsicCor;
            ImSag.Tintrinsic = TintrinsicSag;
            
            
            


        im = cat(2,fliplr(rot90(backgroundImageCor,3)),fliplr(rot90(backgroundImageSag,3)));
        %imlog = log(im-min(im(:))+1);
        if numel(ax.Children)>0
            ax.Children(end).CData = im;%imlog;
        else
            imagesc(im);%or imlog
        end
        set(gca, 'YDir', 'normal');
        colormap(bone)
        
        %reset geometry
        try
            resetPatch()
        catch
            %no geometry exists at initialisation
        end
    end

% Function to close the figure on Enter key press
function closeFigureOnEnter(~, event)
    if strcmp(event.Key, 'return')
        close(gcf);
    end
end

    function updatePatch(handles)
        
        if nargin==0 %at init
            
                    T = eye(3)*1/vxl;
                    T(3,3) = 1;
                    T(3,1) = 25/vxl+1;
                    T(3,2) = 10/vxl;
            try
                if ax.CurrentPoint(1, 1)>(50*scaling)+1
                    T(3,1) = T(3,1) + 50*scaling+1;
                end
            catch
                %no scaling known at init
            end

                    arrayfun(@(x) transformP(x,T),p)
        else
        
            
            p1 = [handles.points(1).YData,handles.points(1).XData];
            p2 = [handles.points(2).YData,handles.points(2).XData];
            
            % Calculate the slope of the line
            slope = (p2(2) - p1(2)) / (p2(1) - p1(1));
            
            % Calculate the angle between the line and the positive y-axis
            angle = -atan(slope);

            % Calculate the translation vector
            translation = p1([2 1]);

            % Create the transformation matrix
            T = [cos(angle), -sin(angle), translation(1);
                 sin(angle), cos(angle),  translation(2);
                 0,          0,           1];
             
             T_scaling = diag([1/vxl 1/vxl 1]);
             
             Ttotal = T*T_scaling;
             for i = 1:numel(p_init)
                 transformP(p(i),Ttotal',p_init{i})
             end
                 
             
             
             
            
            
        end
         function transformP(Pi,T,PiV)
             if nargin==2
                transformed = [Pi.Vertices,ones(size(Pi.Vertices,1),1)]*T;
             else
                 transformed = [PiV,ones(size(PiV,1),1)]*T;
             end
            Pi.Vertices = transformed(:,[1,2]);
             
        end
        
    end

    function resetPatch()
        %first draw in origin
        for i = 1:numel(p_init)
                 p(i).Vertices = p_init{i};
        end
        
        %then warp to center of window
         updatePatch
    end

    function p = plotPatch()
        c0 = [0 0];
        up = [0 1];
        spacing = 2;
        width = 1.5;
        contactheight = 1.5;
        tipdistance = 1;



        x = [-1 1 1 -1]*width/2;
        y = [-1 -1 1 1]*contactheight/2;

        xpi = linspace(0,pi,100);
        y_arc = -sin(xpi)*tipdistance-contactheight/2;
        x_arc = cos(xpi)*width/2;% linspace(-width/2,width/2,100);

        p(1) = patch(x,y+0,'red');
        p(2) = patch(x,y+1*spacing,'red');
        p(3) = patch(x,y+2*spacing,'red');
        p(4) = patch(x,y+3*spacing,'red');

        p(5) = patch(x_arc,y_arc,'blue');

        set(p,'FaceAlpha',0.2)
        

        
       

    end


% Set fixed axes limits
%     xlim(ax, [0, 1]);
%     ylim(ax, [0, 1]);

% Set mouse motion callback function
set(fig, 'WindowButtonMotionFcn', @mouseMoveCallback);
end
