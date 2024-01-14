dicomDir = 'VolumeData1';
dcmds = imageDatastore(dicomDir,'IncludeSubfolders',true,'FileExtensions','.dcm','ReadFcn',@(x) dicomread(x));
%vol = dicomread(dcmds.Files{1});
%vol = squeeze(vol);
%newVol = imresize3(vol,[224,224,224]);
numFiles = length(dcmds.Files);
newDim = [224,224,224];
for i = 1:numFiles
    vol = dicomread(dcmds.Files{i});
    vol = squeeze(vol);
    newVol = imresize3(vol,newDim);
end