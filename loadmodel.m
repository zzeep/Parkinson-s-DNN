function loadmodel(varargin)
path = pwd;
    if string(varargin{1}) == 'cutnet' && string(varargin{2}) == 'Dropout'

        load(strcat(path,'/models/cutnetnoDO.mat'));
        cutnet = lgraph_1;
        DOLayer = dropoutLayer(0.5, 'Name', 'DO');
        cutnet = addLayers(cutnet, DOLayer);
        cutnet = disconnectLayers(cutnet, 'res4a_relu', 'gapool3d');
        cutnet = connectLayers(cutnet, 'res4a_relu', 'DO');
        cutnet = connectLayers(cutnet,  'DO', 'gapool3d');

        if nargin == 3
            fcidx = contains({cutnet.Layers.Name}, 'fc');
            fcl = cutnet.Layers(fcidx);
            newfc = fullyConnectedLayer(fcl.OutputSize, "WeightLearnRateFactor", varargin{3}, 'BiasLearnRateFactor', varargin{3}, 'WeightsInitializer',fcl.WeightsInitializer,'Name', 'new_fc');
            cutnet = replaceLayer(cutnet,fcl.Name,newfc);
        end

        assignin("base","cutnetDO",cutnet);
    elseif string(varargin{2}) == 'Spatial Dropout'
        load(strcat(path,'/models/cutnetnoDO.mat'));
        cutnet = lgraph_1;
        prob = input('probability of dropout layer: ');
        DOLayer = spatialDropout('Probability',prob, 'Name', 'SDO');
        cutnet = addLayers(cutnet, DOLayer);
        cutnet = disconnectLayers(cutnet, 'res4a_relu', 'gapool3d');
        cutnet = connectLayers(cutnet, 'res4a_relu', 'SDO');
        cutnet = connectLayers(cutnet,  'SDO', 'gapool3d');

        if nargin == 3
            fcidx = contains({cutnet.Layers.Name}, 'fc');
            fcl = cutnet.Layers(fcidx);
            newfc = fullyConnectedLayer(fcl.OutputSize, "WeightLearnRateFactor", varargin{3}, 'BiasLearnRateFactor', varargin{3}, 'WeightsInitializer',fcl.WeightsInitializer,'Name', 'new_fc');
            cutnet = replaceLayer(cutnet,fcl.Name,newfc);
        end

        assignin("base","cutnetSDO",cutnet);
    elseif string(varargin{1}) == 'cutnet'
        load(strcat(path,'/models/cutnetnoDO.mat'));
        cutnet = lgraph_1;
        assignin("base","cutnet",cutnet);
    elseif string(varargin{1}) == '3DRN18' && string(varargin{2}) == 'Dropout'
        %Eventually add to directory package, either compiled model or
        %function
        ZaNet = DNNZN();
        DOLayer = dropoutLayer(0.5, 'Name', 'DO');
        ZaNet = addLayers(ZaNet,DOLayer);
        ZaNet = disconnectLayers(ZaNet, 'res5b_relu', 'gap');
        ZaNet = connectLayers(ZaNet, 'res5b_relu', 'DO');
        ZaNet = connectLayers(ZaNet,  'DO', 'gap');
        if nargin == 3
            fcidx = contains({ZaNet.Layers.Name}, 'fc');
            fcl = ZaNet.Layers(fcidx);
            newfc = fullyConnectedLayer(fcl.OutputSize, "WeightLearnRateFactor", varargin{3}, 'BiasLearnRateFactor', varargin{3}, 'WeightsInitializer',fcl.WeightsInitializer,'Name', 'new_fc');
            ZaNet = replaceLayer(ZaNet,fcl.Name,newfc);
        end
        assignin('base', 'RN183DDO', ZaNet);
    elseif string(varargin{1} == '3DRN18')
        ZaNet = DNNZN();
        assignin("base", 'RN183D', ZaNet);
    end
end