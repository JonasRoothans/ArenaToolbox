function [c_out] = A_MNI2ACPC(coordinate)

Tmni2apcpc = inv(makeT);
c = Vector3D(coordinate);
c_out = c.transform(Tmni2apcpc).round(10); %rounded to 10 decimals

    function transformation_matrix = makeT()
        % Define the axes of system A
        X_A = [1 0 0];
        Y_A = [0 1 0];
        Z_A = [0 0 1];
        
        % Define the points AC and PC for system B
        AC = [0 1 -4];
        PC = [0 -24 -2];
        
        % Calculate the midpoint between AC and PC
        midpoint = (AC + PC) / 2;
        
        % Calculate the Y-axis of system B
        Y_B = (AC - PC) / norm(AC - PC); % Normalize the vector to get unit vector
        
        % Calculate the Z-axis of system B (cross product of X_A and Y_A)
        Z_B = cross(X_A, Y_B);
        Z_B = Z_B / norm(Z_B); % Normalize the vector
        
        % Calculate the Y-axis of system B (cross product of Z_B and X_B)
        X_B = cross(Y_B, Z_B);
        
        % Create the rotation matrix
        R = [X_B; Y_B; Z_B];
        
        % Create the translation matrix
        T = eye(4);
        T(1:3, 4) = -midpoint';
        
        % Combine rotation and translation to get the transformation matrix
        transformation_matrix = [R, [0;0;0]; 0 0 0 1] * T;
        
        %switch rows/columns because arena uses flipped transformation matrices
        transformation_matrix = inv(transformation_matrix)';
        
%         % Display the transformation matrix
%         disp('Transformation Matrix:')
%         disp(transformation_matrix);

    end


end

