% Run this script after scriptSetupML, it will connect to jupyter, copy
% files and can terminate the instance

%% Inputs
id = '';
dns = '';
origPath = ''; % Where this instance data started from

%% Jenkins

if exist('id_','var')
    id = id_;
end
if exist('dns_','var')
    dns = dns_;
end
if exist('origPath_','var')
    origPath = origPath_;
end

if isempty(id) || isempty(dns)
    error('Please set id and dns to connect');
end

%% Re-connect with instance
% This function is generated by awsSetCredentials_Private.
awsSetCredentials();
ec2RunStructure = My_ec2RunStructure_DeepLearning();
ec2Instance = awsEC2RunstructureToInstance(ec2RunStructure, id, dns);

%% Run Jupyter 

% Build ssh command to generate a terminal
sshCmd = sprintf('-L localhost:8888:localhost:8888 -i "%s" ubuntu@%s ',...
    ec2Instance.pemFilePath, ec2Instance.dns);

ssh([sshCmd '"jupyter notebook"'],true);

% Present user what to do
waitfor(msgbox({...
    'Copy URL from the terminal that will appear after closing this dialog box.',...
    'Paste to browser, this will be your access to jupyter',...
    'Once online, navigate to ml/runme_x.ipynb - continue from there'}));

%% Once done, exit

answer = inputdlg({'Your Name:', 'Experiment Name: (leave blank if unknown)'},'Click Ok to Save, Cancel to Skip Save',[1 100],{'Yonatan',''});

if ~isempty(answer)
    
    % Figure out dataset name
    [~, origDatasetName] = analyze_origPath (origPath);
    
    % Generate a directory for output.
    modelDirectory = awsModifyPathForCompetability([strtrim(sprintf('%s/%s %s %s', ...
        s3SubjectPath('','_MLModels'), origDatasetName, ...
        strtrim(answer{1}),strtrim(answer{2}))) '/'],true);
    awsMkDir(modelDirectory,true);
    modelDirectoryLinux = strrep(modelDirectory,' ','\ ');
    
    % Take a snapshot
    [status, txt] = awsEC2RunCommandOnInstance(ec2Instance,...
        ['aws s3 sync ~/ml/ ' modelDirectoryLinux]);
    if (status ~= 0)
        error('Couldn''t save a snapshot: %s',txt);
    end
end

% Should we terminate instance
answer = questdlg('Should I Terminate EC2 Machine?','?','Yes','No','No');
if strcmp(answer,'Yes')
    % Terminate instance
    awsEC2TerminateInstance(ec2Instance);
end
