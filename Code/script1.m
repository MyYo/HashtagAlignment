%This script runs Hashtag Alignment
% Step #1: Input Fluorescence Images
% Step #2: Input OCT Data Folder and Configure Hashtag
% Step #3: Find Feducial Marker in Fluorescence Image: ptsPixPosition, ptsId
% Step #4: Find Plane Parameters: u,v,h
% Step #5: Reslice OCT Volume to Find B-Scan That Fits Histology

%% Step #1: Input Fluorescence Images
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%input 1st confocal x-z hashtag image
vidFile_data= 'C:\Users\Edwin\Documents\Hashtag Images\PLGA bead collection\-10_2\Experiment_Series011_z0_ch01.tif';
[pathstr_data,vidName_data,ext_data] = fileparts(vidFile_data)

filenamesplit = strsplit(vidName_data,'_');
channelinfo = filenamesplit{end};
pathstr_data=[pathstr_data '\'];
files = dir([pathstr_data '*' channelinfo ext_data]);

for i=0:1:length(files)-1
    Data_ch1(:,:,i+1)=imrotate(imread([files(i+1).folder '\' files(i+1).name]),180);
end

Data_ch1 = fliplr(Data_ch1);
clear vidFile_data;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%input 1st fluorescence x-z beads image
vidFile_data= 'C:\Users\Edwin\Documents\Hashtag Images\PLGA bead collection\-10_2\Experiment_Series011_z0_ch00.tif';
[pathstr_data,vidName_data,ext_data] = fileparts(vidFile_data);

filenamesplit = strsplit(vidName_data,'_');
channelinfo = filenamesplit{end};
pathstr_data=[pathstr_data '\'];
files = dir([pathstr_data '*' channelinfo ext_data]);

for i=0:1:length(files)-1
    Data_ch0(:,:,i+1)=imrotate(imread([files(i+1).folder '\' files(i+1).name]),180);
end

Data_ch0 = fliplr(Data_ch0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%indicated which slices of confocal dataset to use
indices =[1:5];
histologyFluorescenceIm=mean(Data_ch1(:,:,indices),3);
histologyImage=squeeze(max(Data_ch0(:,:,indices),[],3));

histologyFluorescenceIm = flipud(histologyFluorescenceIm);
histologyImage = flipud(histologyImage);

figure; imagesc(histologyImage); figure; imagesc(histologyFluorescenceIm);
%% Step #2: Input OCT Data Folder and Configure Hashtag

% Input OCT datafolder 
%dataFolder = 'C:\Users\Edwin\Documents\Hashtag Images\10-9-2018\Sample B Mouse Ear\Volume\2018_10_03_03-12-19';
dataFolder = 'C:\MATLAB_Share\Itamar\OCT_Histology\10032018\Flouresnce beads (25 micron) volume\2018_10_04_21-29-05\';
%# Alignment Markers Specifications
%                1    2    3    4    5
lnDist = 1e-6*[-50  +50  -50    0  +100]; %Line distance from origin [m]
lnDir  =      [  0    0    1    1    1]; %Line direction 0 - left right, 1 - up down
lnNames=     { '-x' '+x' '-y' '0y' '+y'}; %Line names

%OCT
OCTVolumeFolder = dataFolder;
OCTVolumePosition = [-1e-3     -1e-3      0; ...     %x,y,z position [m] of the first A scan in the first B scan (1,1)
                     +0.998e-3 +0.998e-3  1984e-6/1.33]'; %x,y,z position [m] of the las A scan in the last B scan (end,end). z is deeper!
                     
% For trdelay 40                 
OCTVolumePosition = OCTVolumePosition - [5.493e-6 0 0; 5.493e-6 0 0]';
OCTVolumePosition(1,2) = (OCTVolumePosition(1,2)- OCTVolumePosition(1,1))*1.026049 + OCTVolumePosition(1,1);
       
dispersionQuadraticTerm = 9.592e-02;  %Use this dispersion Parameter for air-water interface - Wasatch

%Plotting
%plot after step #     1     2     3
isPlotStepResults = [ false true false];

%Enter your own points (optional). Comment out if not in use
%ptsPixPosition = [439.04,258.00;438.98,259.00;438.87,260.00;438.77,261.00;438.72,262.00;438.68,263.00;438.71,264.00;438.69,265.00;438.67,266.00;438.66,267.00;438.57,268.00;438.56,269.00;438.55,270.00;438.44,271.00;438.39,272.00;438.41,273.00;438.12,274.00;438.17,275.00;438.06,276.00;437.88,277.00;437.82,278.00;437.84,279.00;437.78,280.00;437.75,281.00;437.84,282.00;437.64,283.00;437.68,284.00;437.87,285.00;437.70,286.00;437.80,287.00;437.73,288.00;437.64,289.00;437.54,290.00;437.14,291.00;437.13,292.00;437.18,293.00;437.37,294.00;437.24,295.00;437.19,296.00;437.30,297.00;437.11,298.00;437.29,299.00;437.37,300.00;437.40,301.00;437.52,302.00;437.54,303.00;437.47,304.00;437.32,305.00;437.37,306.00;437.33,307.00;437.13,308.00;437.31,309.00;437.18,310.00;437.07,311.00;437.02,312.00;437.07,313.00;437.02,314.00;437.07,315.00;437.12,316.00;436.94,317.00;437.03,318.00;436.97,319.00;436.62,320.00;436.65,321.00;436.55,322.00;436.42,323.00;436.44,324.00;436.52,325.00;436.38,326.00;436.54,327.00;436.58,328.00;436.73,329.00;436.95,330.00;436.85,331.00;436.96,332.00;437.16,333.00;437.08,334.00;437.12,335.00;437.17,336.00;437.24,337.00;437.11,338.00;437.32,339.00;437.15,340.00;436.84,341.00;437.16,342.00;436.94,343.00;437.00,344.00;437.55,345.00;437.40,346.00;436.70,347.00;436.65,348.00;436.15,349.00;436.09,350.00;436.05,351.00;436.29,352.00;436.34,353.00;436.00,354.00;436.46,355.00;436.37,356.00;436.20,357.00;436.53,358.00;435.91,359.00;435.78,360.00;382.23,255.00;382.30,256.00;382.24,257.00;382.06,258.00;381.98,259.00;381.99,260.00;381.98,261.00;381.94,262.00;381.88,263.00;381.96,264.00;381.88,265.00;381.91,266.00;381.83,267.00;381.80,268.00;381.79,269.00;381.70,270.00;381.62,271.00;381.36,272.00;381.28,273.00;381.11,274.00;380.90,275.00;380.74,276.00;380.56,277.00;380.50,278.00;380.41,279.00;380.25,280.00;380.15,281.00;380.04,282.00;379.98,283.00;379.75,284.00;379.63,285.00;379.59,286.00;379.66,287.00;379.60,288.00;379.52,289.00;379.58,290.00;379.57,291.00;379.58,292.00;379.66,293.00;379.74,294.00;379.87,295.00;380.10,296.00;380.16,297.00;380.23,298.00;380.14,299.00;380.27,300.00;380.30,301.00;380.39,302.00;380.51,303.00;380.59,304.00;380.68,305.00;380.70,306.00;380.68,307.00;380.75,308.00;380.73,309.00;380.84,310.00;380.91,311.00;381.04,312.00;381.18,313.00;381.23,314.00;381.20,315.00;381.26,316.00;381.29,317.00;381.36,318.00;381.44,319.00;381.38,320.00;381.36,321.00;381.32,322.00;381.27,323.00;381.17,324.00;381.00,325.00;381.03,326.00;381.11,327.00;381.03,328.00;381.16,329.00;380.98,330.00;381.07,331.00;381.19,332.00;381.15,333.00;381.25,334.00;381.43,335.00;381.59,336.00;381.66,337.00;381.70,338.00;381.83,339.00;381.37,340.00;381.39,341.00;381.47,342.00;381.26,343.00;381.22,344.00;381.26,345.00;381.06,346.00;380.87,347.00;380.65,348.00;380.52,349.00;380.58,350.00;380.62,351.00;97.03,238.00;96.77,239.00;96.58,240.00;96.68,241.00;98.01,242.00;98.08,243.00;98.07,244.00;98.11,245.00;98.14,246.00;98.04,247.00;97.95,248.00;97.70,249.00;97.64,250.00;97.56,251.00;99.13,252.00;99.15,253.00;99.20,254.00;99.23,255.00;99.24,256.00;99.19,257.00;99.32,258.00;99.33,259.00;99.37,260.00;100.36,261.00;100.39,262.00;100.45,263.00;100.45,264.00;100.52,265.00;100.47,266.00;100.45,267.00;100.50,268.00;100.56,269.00;100.48,270.00;101.21,271.00;101.28,272.00;101.38,273.00;101.44,274.00;101.46,275.00;101.71,276.00;101.86,277.00;101.94,278.00;101.85,279.00;102.28,280.00;102.25,281.00;102.46,282.00;102.56,283.00;102.59,284.00;102.57,285.00;102.43,286.00;102.39,287.00;102.32,288.00;102.69,289.00;102.79,290.00;102.78,291.00;103.13,292.00;103.00,293.00;103.20,294.00;103.37,295.00;103.50,296.00;103.70,297.00;103.69,298.00;103.63,299.00;103.63,300.00;103.69,301.00;103.86,302.00;103.83,303.00;103.91,304.00;103.93,305.00;104.11,306.00;104.34,307.00;104.83,308.00;104.89,309.00;104.98,310.00;105.14,311.00;105.09,312.00;105.24,313.00;105.44,314.00;105.67,315.00;105.65,316.00;105.38,317.00;106.10,318.00;106.42,319.00;106.49,320.00;106.78,321.00;106.91,322.00;106.88,323.00;106.87,324.00;106.98,325.00;106.79,326.00;107.04,327.00;107.20,328.00;107.11,329.00;107.01,330.00;107.08,331.00;107.14,332.00;107.14,333.00;107.06,334.00;107.00,335.00;107.06,336.00;106.95,337.00;107.11,338.00;127.27,237.00;127.28,238.00;127.31,239.00;127.37,240.00;127.41,241.00;127.48,242.00;127.61,243.00;127.62,244.00;127.66,245.00;127.71,246.00;127.75,247.00;127.85,248.00;127.93,249.00;127.95,250.00;128.04,251.00;128.08,252.00;128.15,253.00;128.30,254.00;128.41,255.00;128.44,256.00;128.56,257.00;128.61,258.00;128.70,259.00;128.81,260.00;128.91,261.00;128.98,262.00;129.10,263.00;129.24,264.00;129.46,265.00;129.56,266.00;129.65,267.00;129.68,268.00;129.79,269.00;129.86,270.00;129.87,271.00;129.89,272.00;129.96,273.00;130.00,274.00;129.99,275.00;130.24,276.00;130.29,277.00;130.42,278.00;130.58,279.00;130.69,280.00;130.71,281.00;130.84,282.00;130.90,283.00;130.98,284.00;131.14,285.00;131.12,286.00;131.31,287.00;131.35,288.00;131.42,289.00;131.48,290.00;131.45,291.00;131.61,292.00;131.64,293.00;131.90,294.00;131.98,295.00;131.90,296.00;132.02,297.00;132.32,298.00;132.40,299.00;132.49,300.00;132.32,301.00;132.37,302.00;132.41,303.00;132.42,304.00;132.46,305.00;132.46,306.00;132.76,307.00;132.87,308.00;133.14,309.00;133.13,310.00;133.25,311.00;133.40,312.00;133.37,313.00;133.53,314.00;133.43,315.00;133.47,316.00;133.57,317.00;133.64,318.00;133.69,319.00;133.76,320.00;133.94,321.00;133.79,322.00;133.80,323.00;133.83,324.00;133.44,325.00;133.37,326.00;133.47,327.00;133.60,328.00;133.54,329.00;133.43,330.00;133.09,331.00;134.37,332.00;134.60,333.00;134.50,334.00;134.66,335.00;155.14,240.00;155.16,241.00;155.22,242.00;155.30,243.00;155.40,244.00;155.47,245.00;155.53,246.00;155.63,247.00;155.73,248.00;155.82,249.00;155.91,250.00;155.93,251.00;156.02,252.00;156.14,253.00;156.17,254.00;156.24,255.00;156.37,256.00;156.49,257.00;156.52,258.00;156.57,259.00;156.65,260.00;156.76,261.00;156.86,262.00;156.91,263.00;156.97,264.00;157.09,265.00;157.31,266.00;157.36,267.00;157.47,268.00;157.55,269.00;157.57,270.00;157.63,271.00;157.70,272.00;157.80,273.00;157.83,274.00;157.90,275.00;157.93,276.00;158.05,277.00;158.18,278.00;158.34,279.00;158.36,280.00;158.48,281.00;158.66,282.00;158.74,283.00;158.67,284.00;158.76,285.00;158.81,286.00;159.03,287.00;159.05,288.00;159.02,289.00;159.01,290.00;159.05,291.00;159.26,292.00;159.34,293.00;159.48,294.00;159.59,295.00;159.76,296.00;159.79,297.00;159.93,298.00;159.99,299.00;160.02,300.00;160.07,301.00;160.25,302.00;160.21,303.00;160.36,304.00;160.41,305.00;160.50,306.00;160.40,307.00;160.58,308.00;160.56,309.00;160.69,310.00;161.04,311.00;161.01,312.00;161.08,313.00;161.32,314.00;161.38,315.00;161.42,316.00;161.38,317.00;161.54,318.00;161.59,319.00;161.68,320.00;161.86,321.00;161.76,322.00;162.08,323.00;162.06,324.00;162.14,325.00;162.18,326.00;162.24,327.00;162.31,328.00;162.60,329.00;162.43,330.00;162.50,331.00;162.88,332.00;163.04,333.00;162.91,334.00]; %(pixX,pixY)
%ptsId = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5];
                  
%% Step #3: Find Feducial Marker in Fluorescence Image: ptsPixPosition, ptsId
if (~exist('ptsPixPosition','var'))
    % Toggle whether lines are autofit by least squares algorithm
    AutoFit=1;
    [ptsPixPosition, ptsId, ptsLnDist, ptsLnDir] = findLines (histologyFluorescenceIm,lnNames,AutoFit);
    
    s1 = sprintf('%.2f,%.2f;',ptsPixPosition');
    s2 = sprintf('%d,',ptsId);
    fprintf('ptsPixPosition = [%s]; %%(pixX,pixY)\n',s1(1:(end-1)));
    fprintf('ptsId = [%s];\n',s2(1:(end-1)));
end

%% Step #4: Find Plane Parameters: u,v,h

%Find position and direction by line identity
ptsLnDist = lnDist(ptsId); ptsLnDist = ptsLnDist(:);
ptsLnDir  = lnDir(ptsId);  ptsLnDir  = ptsLnDir(:);

%Compute plane parameters
[u,v,h] = identifiedPointsToUVH (ptsPixPosition, ptsLnDist, ptsLnDir);

%Find intercepts
%   h+U*u+V*v=(?;0).
%   U=-(h(2)+V*v(2))/u(1)
V = mean(ptsPixPosition(:,2)); %Take average image height
UX=-(h(2)+V*v(2))/u(2);
%X=u(1)*UX+v(2)*V+h(1); - which is correct?
X=u(1)*UX+v(1)*V+h(1);
UY=-(h(1)+V*v(1))/u(1);
Y=u(2)*UY+v(2)*V+h(2);

%u=[2.5e-6;0;0];
%v=[0;0;2.5e-6];
%h = [-1e-3;-1e-3+2e-6;0];

if isPlotStepResults(2)
    
    fprintf('Pixel Size: |u|=%.3f[microns], |v|=%.3f[microns]\n',norm(u)*1e6,norm(v)*1e6)
    c = cross(u,v); c = c/norm(c);
    fprintf('Angle In X-Y Plane: %.2f[deg], Z Tilt: %.2f[deg]\n',atan2(u(2),u(1))*180/pi,asin(dot(c,[0;0;1]))*180/pi);
    fprintf('Intercept Points. x=%.3f[mm],y=%.3f[mm]\n',1e3*X,1e3*Y);

    %Plot
    figure(2);
    subplot(1,2,1);
    
    %Main Figure
    imagesc(histologyFluorescenceIm);
    hold on;
    
    %Plot points found on figure
    ltxt = 'legend(';
    for i=1:length(lnNames)
        %Plot all the idetified points used in calculation
        if (sum(ptsId==i)>0) %Are there any points in that line
            ltxt = sprintf('%s''%s'',',ltxt,lnNames{i});
            plot(ptsPixPosition(ptsId==i,1),ptsPixPosition(ptsId==i,2),'.');
        end
    end
    ltxt = sprintf('%s''location'',''south'');',ltxt);
    
    %Plot Intercepts
    sx = size(histologyFluorescenceIm,2);
    sz = size(histologyFluorescenceIm,1);
    plot(UX*[1 1],[1 sx],'--r',UY*[1 1],[1 sx],'--r');
    text(UX,sz/4,sprintf('X Intercept\n%.3f[mm]',X*1e3),'Color','red')
    text(UY,sz/4,sprintf('Y Intercept\n%.3f[mm]',Y*1e3),'Color','red')
    
    hold off;
    colormap gray;
    eval(ltxt);
    title('Step #2: Plane Paramaters');
        
    %Plot Plane
    subplot(1,2,2);
    mm = [-1e-3 1e-3];
    for i=1:length(lnNames)
        switch(lnDir(i))
            case 0
                plot(mm,lnDist([i i]));
            case 1
                plot(lnDist([i i]),mm);
        end
        
        if (i==1)
            hold on;
        end
    end
    s = 1:size(histologyFluorescenceIm,2);
    plot(u(1)*s+v(2)*V+h(1),u(2)*s+v(2)*V+h(2),'k');
    plot(u(1)*s(1)+v(2)*V+h(1),u(2)*s(1)+v(2)*V+h(2),'ko');
    axis equal;
    hold off;
    grid on;
    title('Plane');

    pause(0.01);
    
end

%% Step #5: Reslice OCT Volume to Find B-Scan That Fits Histology
if ~exist(OCTVolumeFolder,'dir')
    return; %No OCT to Slice, we are done
end

%Load OCT Processed Volume
OCTVolumeFile = [OCTVolumeFolder '\scanAbs.tif'];
if ~exist(OCTVolumeFile,'file')
    tic;
    %Need to Process OCT Volume first
    
    %Load OCT
    meanAbs = yOCTProcessScan(OCTVolumeFolder, 'meanAbs', ...
        'OCTSystem', 'Wasatch', ...
        'dispersionQuadraticTerm', dispersionQuadraticTerm);
    
    meanAbs = log(meanAbs);
    
    yOCT2Tif(meanAbs,OCTVolumeFile);
    toc;
end

%Reslice
% rOCT = resliceOCTVolume( ...
%     u,v,h,[1 1].*1000, ...
%     OCTVolumeFile,OCTVolumePosition);
thickness = 30; %in units of pixels, with pixel size = average of u and v pix

rOCT = resliceOCTVolume( ...
    u,v,h,[1 1].*size(histologyImage),thickness, ...
    OCTVolumeFile,OCTVolumePosition);

%vol10_1 = rOCT;
%save('vol10_1.mat','vol10_1')

%Plot
figure;
imagesc(mean(rOCT,3));
colormap gray;
axl(1) = gca;
title('OCT Slice');

linkaxes(axl);
pause(0.01);

% Fuse Images

figure; imagesc(imfuse(mean(rOCT,3),imadjust(imresize(imtranslate(histologyImage,[20, -80]),[512*1.1, 512]), [0,1])));
figure; imagesc(mean(rOCT,3)); colormap(gray)
%figure; imagesc(imadjust(histologyImage, [0,0.05]))
return;

