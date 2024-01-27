function [dataOut, infoOut] = transformFcn(dataIn, infoIn)
    shapedVolume = reshape(dataIn, [224, 224, 224, 1]);
    rgbVol = repmat(shapedVolume, [1, 1, 1, 3]);
    infoOut = infoIn;
    dataOut = {rgbVol, infoIn.Label};
end

