% This script will set up ML by opening an instance, copying etc. on aws
% To launch ml instance in aws, we will be following instructions by:
% https://aws.amazon.com/blogs/machine-learning/get-started-with-deep-learning-using-the-aws-deep-learning-ami/
% It will set up a machine using the checkpoint data saved in a specific
% path in aws. It will not generate a data set, but use the existing one.

%% Inputs

% Folder at aws that has the information we need
mainFolder = 's3://delazerdamatlab/Users/OCTHistologyLibrary/_MLModels/2020-05-01 Pix2PixHD/ml/';

%% Lunch & prepare instance
fprintf('%s Launching instance...\n',datestr(datetime));

% This function is generated by awsSetCredentials_Private.
awsSetCredentials();
ec2RunStructure = My_ec2RunStructure_DeepLearning();

% Launch instance
ec2Instance = awsEC2StartInstance(ec2RunStructure,'g4dn.4xlarge');

%% Upload data & prepare it in the right folder
mainFolder = awsModifyPathForCompetability([mainFolder '/'],true);
mainFolder = strrep(mainFolder,' ','\ ');

[status,txt] = awsEC2RunCommandOnInstance (ec2Instance,{...
    'mkdir -p ~/ml' ...
    ['aws s3 sync ' mainFolder ' ~/ml'] ...
    });
%% Capture information user will need & disconnect from instance

% Capture information to keep for reconnect
dns = ec2Instance.dns;
id = ec2Instance.id;

% Disconnect
awsEC2TemporarilyDisconnectFromInstance(ec2Instance);

% Print information
instructions = sprintf('id_=''%s''; dns_=''%s''; scriptEndML;',id,dns);
disp('Next steps: ');
disp(instructions);
fid = fopen('instructions.txt','w');
fprintf(fid,'%s',instructions);
fclose(fid);