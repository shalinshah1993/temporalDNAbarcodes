function data = vid2mat(file, cropPixelNos)
    % Read the video file from the data folder and store it as a .mat file 
    % in tmp folder for downstream use 
    %
    % file should contain full name of video with its extension (eg. AVI)
    %
    % cropPixelNos is between 0 and 512. It indicates how much video should be 
    % cropped (eg. 100). A value 192 will remove 192 border pixels on all
    % sides cropping 512 pixels to 128.
    addpath(genpath(strcat(userpath,'\sauvola')));
    
    fileName = strsplit(file, '.');
    video = VideoReader(strcat('video\', file));
    
    if (video.Height - (2*cropPixelNos) < 1) || ...
                        (video.Width - (2*cropPixelNos) < 1)
        fprintf('Too much frame cropping. None left! Please enter smaller value.\n')
        return;
    end
    data = zeros(ceil(video.Height-2*cropPixelNos), ...
                      ceil(video.Width-2*cropPixelNos), ...
                      ceil(video.FrameRate * video.Duration), 'single');
    
    fprintf('Reading video file by frame: %s\n', file); 
    iframe = 1;
    while hasFrame(video)
         fullFrame = readFrame(video);
         cropFrame = fullFrame(1+cropPixelNos:video.Width-cropPixelNos, ...
                                    1+cropPixelNos:video.Height-cropPixelNos);
        data(:,:,iframe) = cropFrame;
        iframe = iframe + 1;
    end
    
    if exist(strcat('tmp\mat\', fileName{1}, '.mat'), 'file')
        fprintf('Deleting existing tmp file before making one\n'); 
        delete(strcat('tmp\mat\', fileName{1}, '.mat'))
    end
    
    fprintf('Finished reading file %s, saving it as matrix\n', file); 
    save(strcat('tmp\mat\', fileName{1}), 'data', '-v7.3');    
end
