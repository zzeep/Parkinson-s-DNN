%source image file
dicomDir = 'VolumeData1';
%new folder name
exportDir = 'Resized';
%Create directories for control and PD
mkdir (exportDir);
mkdir (strcat(exportDir,'/Control'));
mkdir (strcat(exportDir,'/PD'));
%Generate datastore from volumes
dcmds = imageDatastore(dicomDir,'IncludeSubfolders',true, 'LabelSource','foldernames','FileExtensions','.dcm','ReadFcn',@(x) dicomread(x));
%Get label and number data from datastore
numFiles = length(dcmds.Files);
labels = dcmds.Labels;
%Define new dimensions for DICOM volumes
newDim = [224,224,224];
%Interate through datastore
for i = 1:numFiles
    %Read in DICOM volume
    vol = dicomread(dcmds.Files{i});
    %Squeeze grayscale dimensions out
    vol = squeeze(vol);
    %Resize remaining three dimensions
    newVol = imresize3(vol,newDim);
    %Add back grayscale dimension
    exportVol = reshape(newVol, [newDim(1), newDim(2), 1, newDim(3)]);
    %Determine if file belongs in control or PD directory
    if labels(i) == 'Control'
        writeAddress = strcat(exportDir,'/Control/resized_sub_', extractAfter(dcmds.Files{i}, strlength(dcmds.Files{i})-10));
    else
        writeAddress = strcat(exportDir,'/PD/resized_sub_', extractAfter(dcmds.Files{i}, strlength(dcmds.Files{i})-10));
    end
    %Write resized volume to proper directory
    dicomwrite(exportVol, writeAddress);
end