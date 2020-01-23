function [Scene] = opennii(filename)
%OPENNII Clicking *.nii file triggers this function
%   This prevents unintended loading into MATLAB editor.
eval(['! open "',filename,'"'])
end

