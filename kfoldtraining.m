maxNumCompThreads(16);

resizedDataDir = 'JBresampledvols';
rdcmds = imageDatastore(resizedDataDir,'IncludeSubfolders',true, 'LabelSource','foldernames','FileExtensions','.nii','ReadFcn',@(x) JBaugmentor(x));
rdcmdsVal = imageDatastore(resizedDataDir,'IncludeSubfolders',true, 'LabelSource','foldernames','FileExtensions','.nii','ReadFcn',@(x) JBread(x));

k = 4;
%Use preallocated split for consistency
%load('kpartitionsaugblurnoise.mat');
%get object with indices for k pass
kf = cvpartition(rdcmds.Labels,"KFold",k, 'Stratify', true);
%kf = ksplit.kf;
accuracies=zeros(1,k);
nets = [];


for i = 1:k
    trainidx = kf.training(i);
    validx = kf.test(i);
    %Split up master datastore into training and test(and/or validation)
    xtrain = subset(rdcmds, trainidx);  
    ytrain = rdcmds.Labels(trainidx);
    xvalid = subset(rdcmdsVal, validx);
    options = trainingOptions('adam', ...
       'MiniBatchSize',10, ...
       'MaxEpochs',20, ...
       'L2Regularization',0.0005,...
       'InitialLearnRate',3e-4, ...
       'ValidationData',xvalid,...
       'BatchNormalizationStatistics','population',...
       'ValidationFrequency',15,...
       'Plots','training-progress', ...
       'OutputNetwork','best-validation-loss',...
       'Shuffle','every-epoch',...
       'Verbose',false);
    kfnet = trainNetwork(xtrain, cutnetSDO, options);
    Pred = classify(kfnet, xvalid,'MiniBatchSize',10);
    %calculate accuracy
    accuracy = sum(Pred == xvalid.Labels) / numel(xvalid.Labels);
    fprintf('Fold %d, Accuracy: %.2f%%\n', i, accuracy * 100);
    accuracies(1,i) = accuracy;
    nets = [nets, kfnet];
end

function data = JBread(filename)
    input = niftiread(filename);
    input(isnan(input))=0;
    data = imresize3(input, [224 224 224]);
    %gamma correction
    %data = normalize(data,'range').^0.5 * 255;
    data = repmat(data, [1 1 1 3]);
    data = uint8(data);
    %data = normalize(data, 'range');
    
end

function data = JBaugmentor(filename)
    
    input = niftiread(filename);
    input(isnan(input))=0;
    input = elasticDeformation(input, 25, 1.5);
    rs = [224 224 224];
    numChannels = 3;
    data = imresize3(input, rs);
    %data = normalize(data,'range').^0.5 * 255;
    noisemask = 5 *rand([224 224 224], "double");
    data = 0.98 * data + noisemask;
    %%sd = 0+rand()*0.8;
    %kernel = fspecial3('gaussian',16,sd);
    %data = convn(data, kernel, 'same');
    data = repmat(data, [1 1 1 numChannels]);
    data = uint8(data);
    %data = normalize(data, 'range');  
end

function deformedvol = elasticDeformation(data, scale, sigma)
    [m, n, p] = size(data);
    
    %generate random displacement fields based on hyperparameter
    displacement_field_x = -(scale/2)+scale * rand(m, n, p);  % Displacement along X
    displacement_field_y = -(scale/2)+scale * rand(m, n, p);  % Displacement along Y
    displacement_field_z = -(scale/2)+scale * rand(m, n, p);  % Displacement along Z
    
    %smooth field based on hyperparameter
    displacement_field_x = imgaussfilt3(displacement_field_x, sigma);
    displacement_field_y = imgaussfilt3(displacement_field_y, sigma);
    displacement_field_z = imgaussfilt3(displacement_field_z, sigma);
    
    
    
    % generate a mesh grid of the original coordinates
    [x, y, z] = ndgrid(1:m, 1:n, 1:p);
    
    % calculate displaced coords
    new_x = x + displacement_field_x;
    new_y = y + displacement_field_y;
    new_z = z + displacement_field_z;
    
    deformedvol = NaN(size(data));  % initialize the deformed volume
    
    for i = 1:m
        for j = 1:n
            for k = 1:p
                % make sure coordinates are discrete
                nx = round(new_x(i,j,k));
                ny = round(new_y(i,j,k));
                nz = round(new_z(i,j,k));
                
                if nx >= 1 && nx <= m && ny >= 1 && ny <= n && nz >= 1 && nz <= p
                    %copy data into displaced voxel
                    deformedvol(nx, ny, nz) = data(i,j,k);
                end
            end
        end
    end
    deformedvol = fillmissing(deformedvol, 'linear');
end