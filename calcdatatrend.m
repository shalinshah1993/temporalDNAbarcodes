function calcdatatrend(file, pDegree)
    % This fuction calculates mean for each frame to find z-drift in the
    % data. The polynomial fit is stored in bsline folder which will be
    % used in gettemporalbarcode to subtract GLOBAL Z-drift
    %
    % file should contain full name of video with its extension (eg. AVI)
    %
    % pDegree should be degree of approximating polynomial (usually around 4 - 10)

    % find file inside mat folder (uncropped, undrftcrcted)
    fileName = strsplit(file, '.');
    videoData = matfile(strcat('tmp/mat/', fileName{1}, '.mat'));
    
    % find mean of each frame 
    tic
    [~, ~, nFrames] = size(videoData, 'data');
    dataTrend = zeros(1, nFrames);
    % loop unrolling to reduce the number of loops
    for iFrame = 1:5:nFrames
        dataTrend(iFrame) = mean2(videoData.data(:,:,iFrame));
        dataTrend(iFrame+1) = mean2(videoData.data(:,:,iFrame+1));
        dataTrend(iFrame+2) = mean2(videoData.data(:,:,iFrame+2));
        dataTrend(iFrame+3) = mean2(videoData.data(:,:,iFrame+3));
        dataTrend(iFrame+4) = mean2(videoData.data(:,:,iFrame+4));
    end
    toc

    % plot the averaged data and polynomial fit (smoothed trend)
    figure;
    plot(dataTrend);
    hold on;
    
    % fitting a polynomial using least squares to obtain smooth baseline
    t = (1:length(dataTrend));
    [p, ~, mu] = polyfit(t, dataTrend, pDegree);
    dataTrendFit = polyval(p, t, [], mu); 
    plot(dataTrendFit, 'LineWidth', 2.0);
    
    % save it in bsline folder
    if exist(strcat('tmp/bsline/', fileName{1}, '.mat'), 'file')
        fprintf('Deleting existing tmp file before making one\n'); 
        delete(strcat('tmp/bsline/', fileName{1}, '.mat'))
    end
    fprintf('Finished calculating z-drift.\n'); 
    save(strcat('tmp/bsline/', fileName{1}), 'dataTrendFit', 'dataTrend',...
                                                                     '-v7.3');
end
