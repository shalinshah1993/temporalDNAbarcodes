function estdrift(file, toDisplay, segSize)
    % This function expect a video file which can be used to trace the
    % drift over the time duration of experiment. It will save a drift trace
    % which can be used to correct drift for the entire video. The prefix 
    % for trace file will be \drft_trc\<FILENAME>
    %
    % file is a .AVI file 
    %
    % toDisplay should be 1 or 0 
    %
    % segSize is the number of frames for collecting localizations
    %
    % Created by SHALIN SHAH (shalin.shah@duke.edu)
    % Date created 08/09/2018
    %
    pixelSize = 224;
    
    % Detect particles in all the frames by reading all_pnts_ file
    fileName = strsplit(file, '.');
    fprintf('Loading localizations file\n');
    if ~exist(strcat('tmp/all_pnts/', fileName{1}, '.mat'), 'file')
        fprintf('Detected localizations file does not exists. Creating...\n');
        findalllocalizations(file);
    end
    localizationData = load(strcat('tmp/all_pnts/', fileName{1}, '.mat'));
    
    fprintf('Loaded frame wise localizations. Estimating drift...\n');
    drift = estimateDrift(localizationData.localizationList, segSize, ...
                                localizationData.vidSize, pixelSize, pixelSize);
    if toDisplay
        figure(); plot(drift); legend('X-direction', 'Y-direction')
    end
    
    fprintf('Saving estimated drift trace file...\n')
    
    % delete the old file, if there is
    if exist(strcat('tmp/drft_trc/', fileName{1}), 'file')
        fprintf('Deleting existing file before making one\n'); 
        delete(strcat('tmp/drft_trc/', fileName{1}))
    end
    save(strcat('tmp/drft_trc/', fileName{1}), 'drift', '-v7.3');
end

function  estDrift = estimateDrift(coords, seg_param, img_size, pixel_size, bin_size)
    %{
    descp: Divide video in blocks and estimate drift
    itype: VideoReader object
    rtype: 2 X 1 cell list
    %}
    addpath('lib/RCC');
    [~, estDrift] = DCC(coords, seg_param, img_size, pixel_size, bin_size);
end