%
% File: ImageTest.m
% -------------------
% Author: Erick Blankenberg
% Date 8/8/2018
% 
% Description:
%   Tests out the tile manager, images are stored in the 'TestImages'
%   folder, but are not included in the git by default.
%

close all;
clear all;

tileManager = Manager_Tile;

for index = 1:5
    fileString = sprintf('TestImages/Stitch_%d.tif', index);
    if(exist(fileString, 'file'))
        newestImage = imread(fileString);
        tileManager.addImage(newestImage);
    end
end

figure;
hold on;
image = tileManager.getCompositeImage();
imshow(image);
hold off;