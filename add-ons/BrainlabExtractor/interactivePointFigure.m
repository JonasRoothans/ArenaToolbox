function interactivePointFigure(vd,e)


% Assuming you have the voxeldata object (vd) and the two 3D points (point1 and point2)
point = e.C0; 
normalVector = cross(Vector3D(0,0,1),e.Direction);


% Extract the 2D slice within the bounding box
[backgroundImage,xWorld,yWorld,zWorld] = A_obliquesliceParallelToElectrode(vd,e, normalVector);

%extract lead locations in backgroundimagespace;
center = vd.pointToSubscript(point);
PointOnLead = vd.pointToSubscript(e.getPOL);

    % Create a figure and axes
    fig = figure;
    ax = axes('Parent', fig);
    hold on;
    imagesc(backgroundImage)
    set(gca, 'YDir', 'normal');
    
    % Set aspect ratio to be equal
axis equal;

    % Set up initial point positions
    initialPositions = [100, 100; 150, 150];
    scaling = 20;
    delta = 0.05*scaling; % Distance from the central line
    deltaDepth = 0.2*scaling;
    depthLineLength = 0.2*scaling;

    % Create point scatter plots
    numPoints = size(initialPositions, 1);
    points = gobjects(numPoints, 1);
    for i = 1:numPoints
        points(i) = scatter(ax, initialPositions(i, 1), initialPositions(i, 2), 'ro', 'MarkerFaceColor', 'none');
    end

    % Create initial line between the two points
    lineObj = line(ax, initialPositions(:, 1), initialPositions(:, 2), 'Color', 'k', 'LineStyle', '-');

    % Calculate the direction vector of the central line
    directionVector = [points(2).XData - points(1).XData, points(2).YData - points(1).YData];

    % Calculate the perpendicular direction vector
    perpendicularVector = [-directionVector(2), directionVector(1)];

    % Calculate the parallel lines coordinates

    parallelLine1XCoordinates = [points(1).XData + 0 * perpendicularVector(1), points(2).XData + 0 * perpendicularVector(1)];
    parallelLine1YCoordinates = [points(1).YData + 0 * perpendicularVector(2), points(2).YData + 0 * perpendicularVector(2)];
    parallelLine2XCoordinates = [points(1).XData - 0 * perpendicularVector(1), points(2).XData - 0 * perpendicularVector(1)];
    parallelLine2YCoordinates = [points(1).YData - 0 * perpendicularVector(2), points(2).YData - 0 * perpendicularVector(2)];

    % Create parallel lines
    parallelLine1 = line(ax, parallelLine1XCoordinates, parallelLine1YCoordinates, 'Color', 'k', 'LineStyle', '-');
    parallelLine2 = line(ax, parallelLine2XCoordinates, parallelLine2YCoordinates, 'Color', 'k', 'LineStyle', '-');
    


% Set the initial position of the depth line
[~, lowestPoint ]= min([points(1).YData, points(2).YData]);
centerDepthLine = [points(lowestPoint).XData,points(lowestPoint).YData];

depthLineXCoordinates = [centerDepthLine(1)- deltaDepth * perpendicularVector(1), centerDepthLine(1)+ deltaDepth * perpendicularVector(1)];
depthLineYCoordinates = [centerDepthLine(2)- deltaDepth * perpendicularVector(1), centerDepthLine(2)+ deltaDepth * perpendicularVector(1)];

    % Initialize the depth line
depthLine = line(ax, depthLineXCoordinates, depthLineYCoordinates, 'Color', 'm', 'LineStyle', '-');

updateDepthLine()


    % Set up mouse callback functions
    set(fig, 'WindowButtonDownFcn', @mouseDownCallback);
    set(fig, 'WindowButtonUpFcn', @mouseUpCallback);

    % Initialize variables
    isButtonPressed = false;
    closestPointIndex = 0;
    previousPoint = 0;
    % Mouse down callback function
    function mouseDownCallback(~, ~)
        currentPoint = ax.CurrentPoint(1, 1:2);
        distances = vecnorm(getPointPositions() - currentPoint, 2, 2);
        [~, closestPointIndex] = min(distances);
        previousPoint = currentPoint;
        isButtonPressed = true;

        % Fill the closest point
        set(points(closestPointIndex), 'MarkerFaceColor', 'r');
    end

    % Mouse up callback function
    function mouseUpCallback(~, ~)
        isButtonPressed = false;
        finalPosition = [points(closestPointIndex).XData, points(closestPointIndex).YData];
        disp(['Final position: (', num2str(finalPosition), ')']);

        % Reset the closest point
        set(points(closestPointIndex), 'MarkerFaceColor', 'none');
    end

% Mouse move callback function
function mouseMoveCallback(~, ~)
    if isButtonPressed
        currentPoint = ax.CurrentPoint(1, 1:2);
        if norm([points(1).XData - currentPoint(1), points(1).YData - currentPoint(2)]) > 1*scaling && ...
           norm([points(2).XData - currentPoint(1), points(2).YData - currentPoint(2)]) > 1*scaling
            delta = currentPoint - previousPoint; % Calculate the change in cursor position
            points(1).XData = points(1).XData + delta(1);
            points(1).YData = points(1).YData + delta(2);
            points(2).XData = points(2).XData + delta(1);
            points(2).YData = points(2).YData + delta(2);
        else
            points(closestPointIndex).XData = currentPoint(1);
            points(closestPointIndex).YData = currentPoint(2);
        end
    else
        % Check distance to fill/reset the point
        currentPoint = ax.CurrentPoint(1, 1:2);
        distances = vecnorm(getPointPositions() - currentPoint, 2, 2);
        [minDistance, closestPointIndex] = min(distances);
        if minDistance <= 0.1*scaling
            set(points(closestPointIndex), 'MarkerFaceColor', 'r');
        else
            set(points(closestPointIndex), 'MarkerFaceColor', 'none');
        end
    end

    % Update the line between the two points
    lineObj.XData = [points(1).XData, points(2).XData];
    lineObj.YData = [points(1).YData, points(2).YData];

    % Update the parallel lines
    delta = 0.05*scaling;
    dx = points(2).XData - points(1).XData;
    dy = points(2).YData - points(1).YData;
    normFactor = sqrt(dx^2 + dy^2);
    dxNorm = dx / normFactor;
    dyNorm = dy / normFactor;

    parallelLine1.XData = [points(1).XData + delta * dyNorm, points(2).XData + delta * dyNorm];
    parallelLine1.YData = [points(1).YData - delta * dxNorm, points(2).YData - delta * dxNorm];

    parallelLine2.XData = [points(1).XData - delta * dyNorm, points(2).XData - delta * dyNorm];
    parallelLine2.YData = [points(1).YData + delta * dxNorm, points(2).YData + delta * dxNorm];
    
    % Update the depth line position when dragging the points
    updateDepthLine();

    % Store the current cursor position for the next iteration
    previousPoint = currentPoint;
end


    % Function to get the current positions of the points
    function positions = getPointPositions()
        positions = zeros(numPoints, 2);
        for i = 1:numPoints
            positions(i, 1) = points(i).XData;
            positions(i, 2) = points(i).YData;
        end
    end

% Function to update the position of the depth line
function updateDepthLine()
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
    set(depthLine, 'XData', [depthLineStart(1), depthLineEnd(1)], 'YData', [depthLineStart(2), depthLineEnd(2)]);
end



    % Set fixed axes limits
%     xlim(ax, [0, 1]);
%     ylim(ax, [0, 1]);

    % Set mouse motion callback function
    set(fig, 'WindowButtonMotionFcn', @mouseMoveCallback);
end
