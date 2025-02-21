function ZaNet = DNNZN()
    %Initialize resnet-50 and copy into layer graph object 
    net = resnet18();
    netGraph = layerGraph(net);
    %Get indexable layer array and size from the network
    layers = net.Layers;
    numlayers = size(layers,1);
    %Get input layer; this will be changed first
    inputLayer = layers(1);
    %Create replacement 3d layer with expanded input size
    replacementLayer = image3dInputLayer([224 224 224 3],'Normalization','rescale-zero-one');
    %Replace layer while maintaining connections
    netGraph = replaceLayer(netGraph, inputLayer.Name,replacementLayer, 'ReconnectBy', 'name');
    %Iterate through subsequent layers of DNN
    for i=2:numlayers
        layer = layers(i);
        %Check if layer is a convolutional 2d, replace it with 3d if so
        if isa(layer, 'nnet.cnn.layer.Convolution2DLayer')
            %Filter size of 3d Conv layer is 3d instead of 2d, so we expand it
            newFilter = [layer.FilterSize,max(layer.FilterSize)];
            %Expand stride to 3d for new layer
            newStride = [layer.Stride, max(layer.Stride)];
            %Create 3d copy of weights matrix from previous 2d
            newWeights = zeros(size(layer.Weights,1),size(layer.Weights,2),size(layer.Weights,1), ...
                size(layer.Weights,3),size(layer.Weights,4));
            %Iterate through third dimension layers to populate
                for expIndex = 1:size(layer.Weights,1)
                    %Copy 2d layer into 3d matrix
                    newWeights(:,:,expIndex,:,:) = layer.Weights;
                end
            %Create 3d copy of bias values from previous 2d
            newBias = zeros(size(layer.Bias,1),size(layer.Bias,2),size(layer.Bias,1),size(layer.Bias,3));
            %Iterate through third dimension to populate
                for expIndex = 1:size(layer.Bias,1)
                    %Copy 2d layer into 3d matrix
                    newBias(:,:,expIndex,:) = layer.Bias;
                end
            if strcmp(layer.PaddingMode, 'same')
                padding = 'same';
            else
                padding = layer.PaddingSize(1) + zeros(2,3);
            end
            %Create 3d conv layer using new biases, weights, filters
            replacementLayer = convolution3dLayer(newFilter, layer.NumFilters,'Weights',newWeights,'Bias',newBias,'Stride',newStride, 'PaddingValue', layer.PaddingValue, 'Padding', padding);
            %replacementLayer = convolution3dLayer(newFilter, layer.NumFilters,'Weights',newWeights,'Bias',newBias,'Stride',newStride, 'PaddingValue', layer.PaddingValue, 'Padding', padding, 'WeightLearnRateFactor', 0, 'BiasLearnRateFactor', 0);
            %Replace layer and preserve connections from former layer
            netGraph = replaceLayer(netGraph, layer.Name, replacementLayer,'ReconnectBy','name');
        end
        if isa(layer,'nnet.cnn.layer.BatchNormalizationLayer')
            newTrainedMean = zeros(1,1,1,layer.NumChannels);
            newTrainedVariance = zeros(1,1,1,layer.NumChannels);
            newOffset = zeros(1,1,1,layer.NumChannels);
            newScale = zeros(1,1,1,layer.NumChannels);
            for i = 1:layer.NumChannels
                newTrainedMean(:,:,:,i) = layer.TrainedMean(1,1,i);
                newTrainedVariance(:,:,:,i) = layer.TrainedVariance(1,1,i);
                newOffset(:,:,:,i) = layer.Offset(1,1,i);
                newScale(:,:,:,i) = layer.Scale(1,1,i);
            end       
            replacementLayer = batchNormalizationLayer('TrainedMean',newTrainedMean,'TrainedVariance',newTrainedVariance,'Offset',newOffset,'Scale',newScale);
            netGraph = replaceLayer(netGraph, layer.Name, replacementLayer,'ReconnectBy','name');
        end
        %Check if layer is 2d max pool, replace if it is
        if isa(layer, 'nnet.cnn.layer.MaxPooling2DLayer')
            %Expand pool size to be 3d
            newPoolSize = [layer.PoolSize,max(layer.PoolSize)];
            %Expand stride to be 3d
            newStride = [layer.Stride, max(layer.Stride)];
            %Create 3d max pool layer, using new stride, pool size
            replacementLayer = maxPooling3dLayer(newPoolSize,'Stride',newStride);
            %Replace layer and preserve connections from previous layer
            netGraph = replaceLayer(netGraph, layer.Name, replacementLayer, 'ReconnectBy', 'name');
        end
        %Check if layer is 2d average pooling, replace if it is
        if isa(layer, 'nnet.cnn.layer.GlobalAveragePooling2DLayer')
            %Initialize 3d average pooling layer to replace
            replacementLayer = globalAveragePooling3dLayer();
            %Replace old layer with 3d one, maintain connections
            netGraph = replaceLayer(netGraph, layer.Name, replacementLayer, 'ReconnectBy','name');
        end
        %Check if layer is fully connected
        if isa(layer,'nnet.cnn.layer.FullyConnectedLayer')
            %Initialize new fully connected layer with old biases and weights.
            %replacementLayer = fullyConnectedLayer(layer.OutputSize,'Bias', layer.Bias,'Weights',layer.Weights);
            replacementLayer = fullyConnectedLayer(2, ...
        'Name','new_fc', ...
        'WeightLearnRateFactor',0, ...
        'BiasLearnRateFactor',0);
            %Replace old layer with new fully connected layer (input will autoresize)
            netGraph = replaceLayer(netGraph, layer.Name, replacementLayer, 'ReconnectBy','name');
        end
        if isa(layer,'nnet.cnn.layer.ClassificationOutputLayer')
            replacementLayer = classificationLayer('classes','auto');
            netGraph = replaceLayer(netGraph, layer.Name, replacementLayer, 'ReconnectBy','name');
        end
    end
    ZaNet = netGraph;
end
