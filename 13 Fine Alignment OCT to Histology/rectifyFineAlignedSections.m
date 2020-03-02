function rectifyFineAlignedSections(subjectPath)
%This function takes the fine alinged data tries to correct it to a linear
%function - to reduce noise

%subjectPath = s3SubjectPath('01','LE');

%% Read stack config
stackConfig = awsReadJSON([subjectPath '/Slides/StackConfig.json']);

%% Load stack aligned y position
yStackAligned_mm = ...
    cellfun(@(x)(x(:)'),{stackConfig.stackAlignment.planeDistanceFromOCTOrigin_um},'UniformOutput',false);
yStackAligned_mm = [yStackAligned_mm{:}]'/1e3;
sectionNumber = (1:length(yStackAligned_mm))';

%% Load fine alingned configuration, 
slideConfigs = cell(size(yStackAligned_mm));
slideConfigsJsonPaths = cell(size(yStackAligned_mm));
for i=1:length(slideConfigs)
    nm = stackConfig.sections.names{i};
    
    slideConfigJsonPath = [subjectPath '/Slides/' nm '/SlideConfig.json'];
    slideConfigsJsonPaths{i} = slideConfigJsonPath;
    if awsExist(slideConfigJsonPath,'file')
        slideConfigs{i} = awsReadJSON(slideConfigJsonPath);
    end
end

%% Extract useful data from slide configs
yFineAligned_mm = zeros(size(yStackAligned_mm))*nan;
overallAlignmentQuality = yFineAligned_mm;
yAxisTolerance_um = yFineAligned_mm;
for i=1:length(slideConfigs)
    slideConfig = slideConfigs{i};
    if isempty(slideConfig)
        continue;
    end

    if isfield(slideConfig,'FM') && isfield(slideConfig.FM,'singlePlaneFit_FineAligned')
        yFineAligned_mm(i) = slideConfig.FM.singlePlaneFit_FineAligned.d;
    end
    if isfield(slideConfig,'QAInfo')
        alignmentQA = slideConfig.QAInfo.AlignmentQuality;
        overallAlignmentQuality(i) = alignmentQA.OverallAlignmentQuality;
        yAxisTolerance_um(i) = alignmentQA.YAxisToleranceMicrons;
    end
end

% Compute weight for each fine aligned sample
w = exp(overallAlignmentQuality)./yAxisTolerance_um;
w(isnan(w)) = 0;

%% Rectify each iteration
fig1=figure(100);
set(fig1,'units','normalized','outerposition',[0 0 1 1]);

stackIterations = stackConfig.sections.iterations;
yFineAlignedRectified_mm = zeros(size(yFineAligned_mm))*nan;
plotI = 1;
for i = 1:max(stackIterations)
    isInThisIeration = stackIterations == i;
    yStackAligned_umI = yStackAligned_mm(isInThisIeration)*1e3;
    yFineAligned_umI = yFineAligned_mm(isInThisIeration)*1e3;
    sectionNumberI = sectionNumber(isInThisIeration);
    wI = w(isInThisIeration);
    yAxisTolerance_umI = yAxisTolerance_um(isInThisIeration);
    
    if (sum(wI) == 0)
        % Nothing to fit
        continue;
    end
    
    cf = fit(sectionNumberI,yFineAligned_umI,...
        fittype('poly1'),'Weight',wI);
    p = [cf.p1, cf.p2];
    yFineAlignedRectified_umI = polyval(p,sectionNumberI);
    
    subplot(1,2,plotI);
    plotI = plotI+1;
    plot(sectionNumberI,yStackAligned_umI);
    hold on;
    errorbar(sectionNumberI,yFineAligned_umI,yAxisTolerance_umI, '.');
    plot(sectionNumberI,yFineAlignedRectified_umI);
    hold off;
    ylabel('Plane Distance from OCT Origin [\mum]');
    xlabel('Section #');
    grid on;
    legend(...
        sprintf('Stack Alignment\n(Section Size: %.1f\\mum)',mean(diff(yStackAligned_umI))),...
        'Fine Alignment [User Defined Tolerances]',...
        sprintf('Fine Alignment Poly Fit\n(Bias: %.1f\\mum, Section Size: %.1f\\mum)',...
            mean(yFineAlignedRectified_umI) - mean(yStackAligned_umI),p(1)), ...
        'location','south');
    title(sprintf('%s, Iteration: %d',stackConfig.sampleID,i));
    
    yFineAlignedRectified_mm(isInThisIeration) = yFineAlignedRectified_umI*1e-3;
end

answer = questdlg('Should I upload results to the cloud?','Cloud','Yes','No','No');
if strcmpi(answer,'yes')
   isUpdateCloud = true;
else
    isUpdateCloud = false;
end

if isUpdateCloud
    saveas(fig1,'tmp.png');
    awsCopyFileFolder('tmp.png',[subjectPath ...
        '/Log/13 Fine Alignment OCT to Histology/RectifyFineAlignedSections_' datestr(now,'yyyymmddHHMM') '.png']);
    delete tmp.png
    close(fig1);
end

%% Update slide config
% Loop over all configs and update
for i=1:length(slideConfigs)
    if isnan(yFineAlignedRectified_mm(i))
        continue; %Nothing to update
    end
    slideConfig = slideConfigs{i};
    if isempty(slideConfig)
        continue; % This should never happen
    end
    
    if (~isnan(yFineAligned_mm(i)))
        % This slide has been updated before, just needs a little
        % adjustment
        u = slideConfig.FM.singlePlaneFit_FineAligned.u;
        v = slideConfig.FM.singlePlaneFit_FineAligned.v;
        h = slideConfig.FM.singlePlaneFit_FineAligned.h;
        n = slideConfig.FM.singlePlaneFit_FineAligned.normal;
        v_ = slideConfig.FM.singlePlaneFit_FineAligned.vTypical;
        pixelSize_um = slideConfig.FM.pixelSize_um;
    else
        % This slide wasn't aligned before, so use u,v,h from the stack
        ii = ~isnan(yFineAligned_mm) & stackConfig.sections.iterations == stackConfig.sections.iterations(i);
        ii = find(ii,1,'first');
        u = slideConfigs{i}.FM.singlePlaneFit_FineAligned.u;
        v = slideConfigs{i}.FM.singlePlaneFit_FineAligned.v;
        h = slideConfigs{i}.FM.singlePlaneFit_FineAligned.h;
        n = slideConfigs{i}.FM.singlePlaneFit_FineAligned.normal;
        v_ = slideConfig.FM.singlePlaneFit_FineAligned.vTypical; %v_ and pixel size come from this section
        pixelSize_um = slideConfig.FM.pixelSize_um;
    end
    
    % Rectify by setting the normal distance to be the same as yFineAlignedRectified_mm
    h = h - dot(h,n)*n + yFineAlignedRectified_mm(i)*n;
     
    % Generate a single plane fit (updates)
    slideConfig.FM.singlePlaneFit_FineAligned = spfCreateFromUVH (u,v,h,v_,pixelSize_um);

    if isUpdateCloud
        awsWriteJSON(slideConfig,slideConfigsJsonPaths{i});
    end
end