function findalllocalizations(file, threshold, ...
                                        toDisplayFrames, toDisplayPlots)
    % This function expects a video file which can be used to detect frame
    % by frame localizations. The prefix for trace file will be 
    % \all_pnts\<FILENAME>
    %
    % file is raw .AVI file 
    %
    % threshold this factor is used for detecting localization in each 
    % frame(eg. 3 ~ 5)
    % 
    % toDisplayFrames should be 1 or 0. This shows video frames.
    %
    % toDisplayPlots should be 1 or 0. This shows graphs.
    %
    % Created by SHALIN SHAH (shalin.shah@duke.edu)
    % Date created 08/09/2018
    
    videoObj = VideoReader(strcat('video/', file));
    % This will be resized as per number of localization detected
    localizationList = zeros(int32(videoObj.FrameRate * ...
                                            videoObj.Duration), 3, 'uint16');
    localizations = zeros(int32(videoObj.FrameRate * videoObj.Duration),1);
    iFrame = 1;
    iLength = 1;
    tic
    while hasFrame(videoObj)
        cur_frame = readFrame(videoObj);

        cur_frame(cur_frame < threshold * mean(cur_frame)) = 0;
        th_frame = imregionalmax(cur_frame, 8);

        props = regionprops(th_frame, cur_frame,'WeightedCentroid');
        points = cat(1, props.WeightedCentroid);
        
        if ~isempty(points)
            % [X Y frame#] list as requied by estDrift
            for i = 1:length(points(:,1))
                localizationList(iLength, 1) = points(i,1);
                localizationList(iLength, 2) = points(i,2);
                localizationList(iLength, 3) = iFrame;
                iLength = iLength + 1;
            end
            % number of localizations in each frame
            localizations(iFrame) = size(points, 1);

            if toDisplayFrames
                figure(1);          
                localized_frame = insertShape(cur_frame,'circle', [points(:, 1) ...
                    points(:, 2) 3.*ones(length(points(:, 1)), 1)], 'LineWidth', 1);
                title('Detected Spots'); 
                imshow(localized_frame); 
            end
        end
        iFrame = iFrame + 1;
    end
    toc
    % Indicates if photo-bleach happens over time
    if toDisplayPlots
        figure(2);
        plot(localizations); 
        title('Localizations Trace'); 
    end
    fprintf(['\nMean of #localizations: %f Standard Deviation of',...
        '#localizations: %f\n'], mean(localizations), std(localizations))
    
    fprintf('Finished finding frame wise localizations, saving them...\n'); 
    fileName = strsplit(file, '.');
    vidSize = videoObj.Height; 
    
    % delete the old file, if there is
    if exist(strcat('tmp/all_pnts/', fileName{1}), 'file')
        fprintf('Deleting existing file before making one\n'); 
        delete(strcat('tmp/all_pnts/', fileName{1}))
    end
    save(strcat('tmp/all_pnts/', fileName{1}), 'localizationList', ...
                                            'vidSize','-v7.3');
end