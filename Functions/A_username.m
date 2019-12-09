function [user] = A_username()
%A_USERNAME gets username from OS
%   Detailed explanation goes here
user = char(java.lang.System.getProperty('user.name'));
end

