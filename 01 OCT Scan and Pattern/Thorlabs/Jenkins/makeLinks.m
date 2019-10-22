%This script generates a google form link to submit subject information to
%spreadsheet

%% Inputs
OCTVolumesFolder = 's3://delazerdamatlab/Users/OCTHistologyLibrary/LC/LC-06/OCTVolumes/';

if (exist('OCTVolumesFolder_','var'))
    OCTVolumesFolder = OCTVolumesFolder_;
end

OCTVolumesFolder = awsModifyPathForCompetability([OCTVolumesFolder '\']);
SubjectFolder = awsModifyPathForCompetability([OCTVolumesFolder '..\']);

%% Load JSONs with information
scanJson = awsReadJSON([OCTVolumesFolder 'ScanConfig.json']);
subjectJson = awsReadJSON([SubjectFolder 'Subject.json']);
numberofSlides = 15;

%% Make the link
yn = @(x)strtrim(char(('Yes'*x + 'No '*(1-x))));

lnk = ['https://docs.google.com/forms/d/e/1FAIpQLSfs2A8xJZYwZ3MqPGTaO2heeNDNzk5UXGbMLQjPxFNPOHB6Ug/viewform?usp=pp_url', ...
    '&entry.2018843122=', subjectJson.sampleId, ...
    '&entry.202754933=',  num2str(numberofSlides),...
    '&entry.2021266855=', scanJson.whenWasItScanned,...
    '&entry.823500759=',  scanJson.gitBranchUsedToScan, ...
    '&entry.2124370862=', scanJson.volumeScannedBy, ...
    '&entry.2015958899=', yn(subjectJson.isFreshHumanSample),...
    '&entry.534747723=',  subjectJson.samePatientAsSampleWithId,...
    '&entry.1130223820=', subjectJson.age,...
    '&entry.1795601743=', subjectJson.gender,...
    '&entry.1025323321=', subjectJson.sampleLocation,...
    '&entry.325426546=',  subjectJson.side,...
    '&entry.328964769=',  subjectJson.possiblePatientDiagnosis,...
    '&entry.1525059716=', subjectJson.sampleType,...
    '&entry.1668699639=', subjectJson.fitzpatrickSkinType,...
    ''];
lnk = strrep(lnk,' ','+');

%% Display link
disp('Go to this link to submit this scan as a form');
disp(lnk);

%% Write link to file
fid = fopen('out.txt','w');
fprintf(fid,'%s',lnk);
fclose(fid);