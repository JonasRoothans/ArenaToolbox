function [Scene] = opennii(filename)
%OPENNII opens a nifti file by system default tool.
%   This prevents unintended loading into MATLAB editor.
eval(['! open ',filename])
end

