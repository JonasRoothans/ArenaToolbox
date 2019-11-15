function [user] = A_username()
%A_USERNAME Summary of this function goes here
%   Detailed explanation goes here
user = char(java.lang.System.getProperty('user.name'));
end

