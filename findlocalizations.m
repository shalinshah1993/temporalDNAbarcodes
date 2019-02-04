function findlocalizations(file, prefix, toDisplay, backPrctlThreshold, ...
                                                            gnpPrctlThreshold)
    % Read the video matrix file from the tmp folder and compute
    % localizations list which can be stored in tmp folder for downstream
    % use
    %
    % file should contain full name of video with its extension (eg. AVI)
    %
    % prefix is either filt, mat, drft_crct etc.
    %
    % toDisplay should be 0 or 1. Value 1 during debugging to vizualize
    %
    % backPrctlThreshold must be around 95 ~ 98 as the lower percentile is
    % all gaussian noise in the image
    %
    % gnpPrctlThreshold must be around 99.9 ~ 99.98. It is used to filter GNP
    % particles detected. 
    addpath('lib/sauvola');
    
    % Read the collected video matrix file from tmp folder using file
    fprintf('Loading mat file video stack...\n'); 
    fileName = strsplit(file, '.');
    if ~exist(strcat('tmp/', prefix, '/', fileName{1}, '.mat'), 'file')
        fprintf('mat file for video does not exists.\n'); 
        return
    end
    fileData = matfile(strcat('tmp/', prefix, '/', fileName{1}, '.mat'));
    tic
    video = fileData.data;
    toc
    
    % factor multipled with max pixel value to remove GNP spots, if
    % possible. 
    fprintf('Processing video stack...\n'); 
    localizationList= detect_spots(video, backPrctlThreshold,...
                                                   gnpPrctlThreshold, toDisplay);
    
    fprintf('Found %d localizations\n', length(localizationList));

    if exist(strcat('tmp/pnts/', fileName{1}, '.mat'), 'file')
        fprintf('Deleting existing tmp file before making one\n'); 
        delete(strcat('tmp/pnts/', fileName{1}, '.mat'));
    end

    fprintf('Finished reading file, saving it as matrix\n'); 
    save(strcat('tmp/pnts/', fileName{1}), 'localizationList','-v7.3');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function globalPoints = detect_spots(video, backPrctlThreshold, ...
                                             gnpPrctlThreshold, DISPLAY_PLOTS)
    %{
    descp: Filter image, threshold and find localizations. Detect particles
    in drift corrected (infiltered) frames and return coordinates.
    itype: VideoReader object, int
    rtype: cell list
    %}
    WIDTH = length(video(1, :, 1));
    HEIGHT = length(video(:, 1, 1));
    FRAMES = length(video(1, 1, :));
    
    % 1) average Z-project stack and crop borders to remove border artifacts
    zProjImg = sum(video, 3);
    borderSize = 3;
    cropped = zProjImg(borderSize:WIDTH - borderSize, ...
        borderSize:HEIGHT - borderSize);
    meanZProjImg = double(cropped)./double(FRAMES);
    
    % 2) percentile threshold image to create GNP mask
    gnpThreshold = prctile(meanZProjImg(:), gnpPrctlThreshold);
    % subtract the dialated mask from original image to remove GNP
    gnpMask = (meanZProjImg > gnpThreshold);
    gnpMaskDilated = imdilate(gnpMask, strel('disk', 5));
    gnpFiltImg = meanZProjImg;
    gnpFiltImg(gnpMaskDilated) = mean(meanZProjImg(:));
    
    % 3) Remove border artifacts and uneven background
    lpMask = averagefilter(gnpFiltImg, [10 10], 'replicate');
    backCrctImg = gnpFiltImg - lpMask;
    
    % 4) smoothen and threshold image using local mean as threshold
    backThrsld = prctile(backCrctImg(:), backPrctlThreshold);
    backMask = backCrctImg <= backThrsld;
    backCrctImg(backMask) = 0;
    smoothImg = imgaussfilt(backCrctImg, 1);
    
    % 5) detect particles in thresholded image
    thImg = imregionalmax(smoothImg, 8);
    % find weighted centroid using threshold and smooth frame
    props = regionprops(thImg, smoothImg,'WeightedCentroid');
    localPoints = int16(cat(1, props.WeightedCentroid)) + borderSize;
    
    if DISPLAY_PLOTS
        figure();
        subplot(3, 2, 1); imagesc(meanZProjImg);
        subplot(3, 2, 2); imagesc(gnpFiltImg);
        subplot(3, 2, 3); imagesc(backCrctImg);
        subplot(3, 2, 4); imagesc(smoothImg);
        subplot(3, 2, 5); imagesc(thImg);
    end
    
    % 6) apply a strict global filter to remove more points
    globalPoints = [];
    for p = 1:length(localPoints(:, 1))
        if zProjImg(localPoints(p, 1), localPoints(p, 2)) > mean(gnpFiltImg(:))
            globalPoints = [globalPoints; localPoints(p, :)];
        end
    end
    fprintf('Removed %d points using global mean.\n', ...
                                size(globalPoints, 1) - size(localPoints, 1));
    
    %(X, Y) list by frame
    if ~isempty(globalPoints) && DISPLAY_PLOTS
        localized_frame = insertMarker(gnpFiltImg, [globalPoints(:, 1)-borderSize, ...
            globalPoints(:, 2)-borderSize], 'o', 'Color', 'r', 'Size', 2);
        title('Detected Spots'); 
        subplot(3, 2, 6); 
        imagesc(localized_frame);
    end
    
    figure; histogram(zProjImg); set(gca, 'YScale', 'log');
end