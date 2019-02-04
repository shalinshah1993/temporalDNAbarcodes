function cropmat(file, prefix, cropPixelNos)
    % Read the full mat file from the prefix folder and crop it. The
    % cropped mat file is stored as crop\<file>.mat
    %
    % file should contain full name of mat file
    %
    % cropPixelNos is between 0 and 512. It indicates how much video should be 
    % cropped (eg. 100). A value 192 will remove 192 border pixels on all
    % sides cropping 512 pixels to 128.
    
    fileName = strsplit(file, '.');
    inpMatFile = matfile(strcat('tmp/', prefix, '/', fileName{1}, '.mat'));
    [height, width, nFrames] = size(inpMatFile, 'data');
    
    if exist(strcat('tmp/crop/', fileName{1}, '.mat'), 'file')
        fprintf('Deleting existing tmp file before making one\n'); 
        delete(strcat('tmp/crop/', fileName{1}, '.mat'))
    end 
    outMatFile = matfile(strcat('tmp/crop/', fileName{1}, '.mat'));
    
    if (height - (2*cropPixelNos) < 1) || (width - (2*cropPixelNos) < 1)
        fprintf('Too much frame cropping. None left! Please enter smaller value.\n')
        return;
    end
    
    % crop frames of full mat file and write them to
    fprintf('Reading .mat file by frame: %s\n', file); 
    for iFrame = 1 : 2 : nFrames
        fullFrameA = inpMatFile.data(:,:, iFrame);
        cropA = fullFrameA(1+cropPixelNos:width-cropPixelNos, ...
                                1+cropPixelNos:height-cropPixelNos);
        
        fullFrameB = inpMatFile.data(:,:, iFrame+1);
        cropB = fullFrameB(1+cropPixelNos:width-cropPixelNos, ...
                                1+cropPixelNos:height-cropPixelNos);

        [rows, cols] = size(cropA);
        outMatFile.data(1:rows, 1:cols, iFrame:iFrame+1) = cat(3, cropA, cropB);
    end
    
    fprintf('Finished cropping mat file: %s\n', file); 
end
