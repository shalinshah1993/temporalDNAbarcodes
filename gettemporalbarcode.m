function gettemporalbarcode(file, prefix)
    % This function will find list of localizations and noise-free video
    % mat data to extract a list of temporal barcodes for each localization
    %
    % file should contain full name of video with its extension (eg. AVI)
    %
    % prefix is either filt, mat, drft_crct etc.
    
    fileName = strsplit(file, '.');
    
    % Check if filtered video data in .mat format exists
    if ~exist(strcat('tmp/', prefix, '/', fileName{1}, '.mat'), 'file')
        fprintf('cannot find noise-free video data in tmp folder\n');
        return
    end
    % Check if localizations list in .mat format exists
    if ~exist(strcat('tmp/pnts/', fileName{1}, '.mat'), 'file')
        fprintf('cannot find localizations lists in tmp folder\n');
        return
    end
    
    % At this point, all the required data for finding temporal barcodes is
    % computed (or exists). 
    fprintf(['Finished finding (or generating) localizations list and', ...
    ' noise-free video data. \n'])
    videoData = matfile(strcat('tmp/', prefix, '/', fileName{1}, '.mat'));
    tic
    video = videoData.data;
    toc
    localizationsData = load(strcat('tmp/pnts/', fileName{1}, '.mat'));
    localizations = localizationsData.localizationList;
    
    % Find the z-axis drift from basline folder
    trendFile = matfile(strcat('tmp/bsline/', fileName{1}, '.mat'));
    
    % apply a function to subtract spatially GLOBAL data mean
    fprintf('Correcting baseline from the video to remove Z-drift\n');
    zCrctVideo = removezdrift(video, trendFile.dataTrendFit);
    
    % Generate temporal barcode assuming 3 X 3 Gaussian PSF
    fprintf('Generating temporal barcodes from video stack\n');
    tempBarcodesList = calctemporalbarcode(zCrctVideo, localizations);
    
    % apply wavelet filter to the barcodes before de-noise
    fprintf('Denoising temporal barcodes using wavelet filter\n');
    filtBarcodesList = cellfun(@(x) denoisetemporalbarcode(x, trendFile.dataTrendFit), ...
                                tempBarcodesList, 'UniformOutput',false);
                                                  
    if exist(strcat('tmp/brcd/', fileName{1}, '.mat'), 'file')
        fprintf('Deleting existing tmp file before making one\n'); 
        delete(strcat('tmp/brcd/', fileName{1}, '.mat'))
    end
    
    figure;  
    histogram([filtBarcodesList{:}]);  set(gca, 'YScale', 'log')
    l = legend(fileName{1}); set(l,'FontSize', 16); 
    grid on; grid minor; set(gca, 'LineWidth', 2.0); axis tight
    xlabel('intensity'); ylabel('counts'); set(gca, 'YScale', 'log')
    
    fprintf('Finished generating %d barcodes.\n', size(filtBarcodesList, 2)); 
    save(strcat('tmp/brcd/', fileName{1}), 'filtBarcodesList',...
                                                'tempBarcodesList', '-v7.3');
end

function crctVideo = removezdrift(video, dataTrend)

    % remove image mean to reduce z-drift and subtract local background 
    addpath('lib/sauvola');
    
    [~, ~, nFrames] = size(video);
    crctVideo = double(video);
     tic
     for iFrame = 1:nFrames
         % subtract image mean per frame to mitigate z-drift effects
         crctVideo(:,:,iFrame) = double(video(:,:,iFrame)) - dataTrend(iFrame);
         
         % local high pass filter for background noise removal
         meanFilt = averagefilter(crctVideo(:,:,iFrame), [20 20], 'replicate');
         crctVideo(:,:,iFrame) = crctVideo(:,:,iFrame) - meanFilt;
     end
    toc
end

function tempBarcodesList = calctemporalbarcode(video, localizations)
    
    % Generate all the temporal barcodes assuimg 3X3 PSF
    nTracks = length(localizations);
    tempBarcodesList = cell(1, nTracks);
    for iTrack = 1 : nTracks
        centroidX = localizations(iTrack, 1);
        centroidY = localizations(iTrack, 2);
        
        % gaussian weight to remove noisy binding events
        W1 = 6/18; W2 = 2/18; W3 = 1/18;
        tempBarcodesList{iTrack}(:) = ...
                            W1.*video(centroidX, centroidY, :) +  ...
                            W2.*video(centroidX + 1, centroidY, :) + ...
                            W2.*video(centroidX, centroidY + 1, :) + ...
                            W2.*video(centroidX - 1, centroidY, :) + ...
                            W2.*video(centroidX, centroidY - 1, :) + ...
                            W3.*video(centroidX + 1, centroidY + 1, :) + ...
                            W3.*video(centroidX - 1, centroidY - 1, :) + ...
                            W3.*video(centroidX + 1, centroidY - 1, :) + ...
                            W3.*video(centroidX - 1, centroidY + 1, :);
    end
end

function filtbarcode = denoisetemporalbarcode(temporalBarcode, dataTrend)
    
    % apply wavelet filter to remove shot noise and remove offset
    filtbarcode = wden(temporalBarcode, 'modwtsqtwolog', 's', 'mln', 8, 'haar'); 

%     figure(1);
%     clf;
%     subplot(4, 1, 1);
%     plot(temporalBarcode + dataTrend); 
%     subplot(4, 1, 2);
%     plot(temporalBarcode); 
%     subplot(4, 1, 3); 
%     plot(filtbarcode);
%     subplot(4, 1, 4);
%     histogram(filtbarcode)
end
