function lif2mat(file)
    % Open LEICA lif file and convert it to mat file for further matlab
    % processing. Inside the .mat file, there will be one data variable
    % which contains a 3D matrix of video frames
    %
    % file is the name of the lif file which should reside in lif folder
    %
    % Created by SHALIN SHAH (shalin.shah@duke.edu)
    % Date created 08/14/2018
    
    % video width and height are always 512
    frameSize = 512;        
    % Add bio format library to path variable
    addpath('lib/bfmatlab');
    
    % All the lif files reside in lif folder
    lifData = bfopen(strcat('lif/', file)); 
    fileName = strsplit(file, '.');
    % delete  the mat file if it already exists
     if exist(strcat('tmp/mat/', fileName{1}, '.mat'), 'file')
        fprintf('Deleting existing tmp file before making one\n'); 
        delete(strcat('tmp/mat/', fileName{1}, '.mat'))
    end
    % Create a writable mat file to process data in chunks
    matFile = matfile(strcat('tmp/mat/', fileName{1}), 'Writable', true);

    % change cell array to 3D matrix (x, y, #frame) by 3D concat
    fprintf('Writing .mat file data...\n');
    nFrames = 0;
    [nSubFile, ~] = size(lifData);
    for iSubFile = 1 : nSubFile
        [iFrames, ~] = size(lifData{iSubFile, 1});
        
        frameByCells = lifData{iSubFile, 1}(:,1);
        matFile.data(1:frameSize, 1:frameSize, nFrames+1:nFrames+iFrames) ...
                                                    = cat(3, frameByCells{:});
        nFrames = nFrames + iFrames;
    end

    % display the variables stored in mat file
    whos('-file',strcat('tmp/mat/', fileName{1}))

end