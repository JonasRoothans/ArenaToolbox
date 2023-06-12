function fig = interactivePointFigure(vd,e)
% Create a figure and axes
fig = figure;
ax = axes('Parent', fig);
axis off
hold on;


%make cross-section
ImCor = [];
ImSag = [];
updateSlice()

%create electrodes and append the transormationmatrix
scaling = 1/ImCor.pxl;
delta = 1; % Distance from the central line
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

% Initialize variables
isButtonPressed = false;
closestPointIndex = 0;
previousPoint = 0;
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
        
        
        
        % Set the initial position of the depth line
        [~, lowestPoint ]= min([points(1).YData, points(2).YData]);
        centerDepthLine = [points(lowestPoint).XData,points(lowestPoint).YData];
        
        depthLineXCoordinates = centerDepthLine(1)+[-5 5];
        depthLineYCoordinates = centerDepthLine(2)-[tipoffset tipoffset]*scaling;
        
        % Initialize the depth line
        handles.depthLine = line(ax, depthLineXCoordinates, depthLineYCoordinates, 'Color', 'r', 'LineStyle', '-');
        handles.points = points;
        updateDepthLine(handles)
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
        currentPoint = ax.CurrentPoint(1, 1:2);
        if currentPoint(1)<51*scaling
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

            if ax.CurrentPoint(1,1)<51*scaling
                points = Ecor.points;
                handles = Ecor;
                
            else
                points = Esag.points;
                handles = Esag;
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
            if ax.CurrentPoint(1, 1)<51*scaling
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

    function updateSlice()
        
        % Extract the 2D slice within the bounding box
        [backgroundImageCor,Tcor,TintrinsicCor] = A_obliquesliceParallelToElectrode(vd,e, 'cor');
        [backgroundImageSag,Tsag,TintrinsicSag] = A_obliquesliceParallelToElectrode(vd,e, 'sag');
        
        %pxl size
        
         
        
        try
            ImCor.T = Tcor;
            ImSag.T = Tsag;
            ImCor.LeadPos = abs(TintrinsicCor(4,[1,3]));
            ImSag.LeadPos = abs(TintrinsicSag(4,[2,3]));
            ImCor.pxl = max(max(TintrinsicCor(1:3,1:3)));
            ImSag.pxl = max(max(TintrinsicSag(1:3,1:3)));
            ImCor.Tintrinsic = TintrinsicCor;
            ImSag.Tintrinsic = TintrinsicSag;
            
            
            
        catch
        end

        im = cat(2,fliplr(rot90(backgroundImageCor,3)),fliplr(rot90(backgroundImageSag,3)));
        imlog = log(im-min(im(:))+1);
        if numel(ax.Children)>0
            ax.Children(end).CData = imlog;
        else
            imagesc(imlog)
        end
        set(gca, 'YDir', 'normal');
        colormap(bone)
    end

% Function to close the figure on Enter key press
function closeFigureOnEnter(~, event)
    if strcmp(event.Key, 'return')
        close(gcf);
    end
end



% Set fixed axes limits
%     xlim(ax, [0, 1]);
%     ylim(ax, [0, 1]);

% Set mouse motion callback function
set(fig, 'WindowButtonMotionFcn', @mouseMoveCallback);
end
