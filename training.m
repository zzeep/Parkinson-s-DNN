resizedDicomDir = 'Resized';
rdcmds = imageDatastore(resizedDicomDir,'IncludeSubfolders',true, 'LabelSource','foldernames','FileExtensions','.dcm','ReadFcn',@(x) dicomread(x));
[imdsTrain,imdsValidation] = splitEachLabel(rdcmds,0.75,'randomized');
tranimdsTrain = transform(imdsTrain,@transformFcn,'IncludeInfo',true);
tranimdsValidation = transform(imdsValidation,@transformFcn,'IncludeInfo',true);
options = trainingOptions('sgdm', ...
    'MiniBatchSize',1, ...
    'MaxEpochs',6, ...
    'InitialLearnRate',1e-4, ...
    'Shuffle','every-epoch', ...
    'ValidationData',tranimdsValidation, ...
    'ValidationFrequency',3, ...
    'Verbose',false, ...
    'Plots','training-progress');
netTransfer = trainNetwork(tranimdsTrain,netGraph,options);
