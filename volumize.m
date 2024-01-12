%name output folder
toFolder = input('enter folder name for 3d volumes\n','s');
%name path for subject slices
path = strcat(input('enter file path for directory of subjects\n','s'));
%create output folder
mkdir (toFolder);
%create cell array of each subject file
S = dir(fullfile(path,'*'));
N = setdiff({S([S.isdir]).name},{'.','..'}); % list of subfolders of D.
%iterate through all subjects in file
for i = 1:numel(N)
    %find slices in subject folder
    imageFolder = dir(fullfile(path,N{i},'*','*','*','*'));
    %create 3d dicom volume from slices in folder
    volume = dicomreadVolume(imageFolder(1).folder);
    %create volume name by subject
    volumeName = strcat(toFolder,'/sub_',N{i},'.dcm');
    %write to output folder using volume name
    dicomwrite(volume, volumeName);
end
