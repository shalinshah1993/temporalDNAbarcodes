function getstatechain(file, msBandwidth, onPeakNo, dbPeakNo, expStates)
    % This function will find list of localizations and noise-free video
    % mat data to extract a list of temporal barcodes for each localization
    %
    % file should contain full name of video with its extension (eg. AVI)
    %
    % msBandwidth is the width for meanshift clustering (eg. 50). Higher
    % the value lesser the number of peaks and vice versa
    %
    % onPeakNo is the minimum number of on peaks required for signal
    % consideration (eg. 10). 
    %
    % dbPeakNo is the minimum number of double-blink peaks required for signal
    % consideration (eg. 5). 
    %
    % expStates is the number of state expected in the signal

    fileName = strsplit(file, '.');
    addpath('lib/meanshift/')
    
    % Check if temporal barcode data in .mat format exists
    if ~exist(strcat('tmp/brcd/', fileName{1}, '.mat'), 'file')
        fprintf('cannot find noise-free video data in tmp folder\n');
        return
    end
    % Check if localizations list in .mat format exists
    if ~exist(strcat('tmp/pnts/', fileName{1}, '.mat'), 'file')
        fprintf('cannot find localizations lists in tmp folder\n');
        return
    end
    localizationsData = load(strcat('tmp/pnts/', fileName{1}, '.mat'));
    localizations = localizationsData.localizationList;
    filtLocalization = transpose(mat2cell(localizations, ...
                                            ones(1, size(localizations, 1))));
   
    fileData = load(strcat('tmp/brcd/', fileName{1}, '.mat'));
    filtData = fileData.filtBarcodesList;
    rawData = fileData.tempBarcodesList;
    
    % apply cell function to generate state chain, remove single state sigs
    fprintf('Applying mean-shift clustering algorithm for state chain\n');
    threshSig = cellfun(@(x, y) applythreshold(x, y, msBandwidth, expStates), ...
                                    filtData, rawData, 'UniformOutput',false);
    filtData(cellfun(@(x) any(isnan(x)),threshSig)) = [];
	filtLocalization(cellfun(@(x) any(isnan(x)),threshSig)) = [];
    threshSig(cellfun(@(x) any(isnan(x)),threshSig)) = [];
    fprintf('Filtered %d/%d signals using mean-shift\n', ...
                          length(rawData)-length(threshSig), length(rawData));                                                
    
    % filter based on number of signal peaks in the thresholded signal
    fprintf('Applying peak based filtering to remove non-specific binding\n');
    filt1 = cellfun(@(x, y) applypeakfilter(x, y, onPeakNo, dbPeakNo), ...
                                    threshSig, filtData, 'UniformOutput',false);
	filtData(cellfun(@(x) any(isnan(x)),filt1)) = [];
    filtLocalization(cellfun(@(x) any(isnan(x)),filt1)) = [];
    filt1(cellfun(@(x) any(isnan(x)),filt1)) = [];
    fprintf('Filtered %d/%d signals using number of peaks\n', ...
                          length(threshSig)-length(filt1), length(threshSig));    
    
    % FINAL FILTER- human supervision to remove convoluted signals
    fprintf('Applying human filter to select final set of %d signals\n',...
                                                               length(filt1));
    filt2 = cellfun(@(x, y) applyhumanfilter(x, y), ...
                                   filt1, filtData, 'UniformOutput',false);
    filtData(cellfun(@(x) any(isnan(x)),filt2)) = [];
    filtLocalization(cellfun(@(x) any(isnan(x)),filt2)) = [];
    filt2(cellfun(@(x) any(isnan(x)),filt2)) = [];
    fprintf('Selected %d signals for final analysis\n', length(filt2)); 
                      
	stateChain = filt2;
    temporalBarcode = filtData;
    localizations = filtLocalization;
    
    
    % save filtered signals before generating stats
    save(strcat('tmp/st_chn/', fileName{1}), 'stateChain', 'localizations',...
                                                     'temporalBarcode', '-v7.3');
end



function thrshBarcode = applythreshold(temporalBarcode, raw, msBandwidth, expStates)
        
    % threshold signal using a bandwidth value and bimodal distribution
    [meanOfPeaks, thrshBarcode, ~] = HGMeanShiftCluster(...
                            temporalBarcode, msBandwidth, 'gaussian', 0);
    
    % remove full-noise data with only 1 peak
    if length(meanOfPeaks) ~= expStates
        thrshBarcode = nan;
        return
    end
    
    % since the start point is randomly selected the peaks are not always sorted                    
	[sOutput, origIds] = sort(meanOfPeaks, 'ascend');
    sortedThBarcode = zeros(length(thrshBarcode), 1);
    for i = 1 : length(meanOfPeaks)
        sortedThBarcode(thrshBarcode == find(meanOfPeaks == sOutput(i))) = i;
    end
    thrshBarcode = sortedThBarcode;
    
    % plot all the thresholding steps to compare with preprocessed signal
%     figure(2);
%     clf;
%     subplot(4, 1, 1);
%     plot(temporalBarcode);
%     hold on;
%     for i = 1:length(meanOfPeaks)
%         plot([0 length(temporalBarcode)], [meanOfPeaks(i) meanOfPeaks(i)],...
%                     ':', 'LineWidth', 2.0)
%     end
%     subplot(4, 1, 2);
%     stairs(thrshBarcode, 'LineWidth', 2.0); 
%     subplot(4, 1, 3);
%     histogram(temporalBarcode);
%     set(gca, 'YScale', 'log')
%     hold on;
%     for i = 1:length(meanOfPeaks)
%         line([meanOfPeaks(i) meanOfPeaks(i)], ylim, 'LineWidth', 2, 'Color', 'r');
%     end
%     
%     subplot(4, 1, 4);
%     plot(raw);
%     
%     getpeakcount(thrshBarcode);
end

function output = applypeakfilter(threshSignal, raw, onPeakNo, dbPeakNo)
    % filter signals based on the number of peaks found. This helps to
    % remove non-specific binding data since their activity is high
    %
    % threshSignal is the classified signal (eg. 0 0 0 0 1 1 2 1 1 0 0)
    %
    % threshPeakNos is minimum peaks required for signal consideration (eg.
    % 10)
    
    output = threshSignal;
    [onPeaks, dbPeaks] = getpeakcount(threshSignal);
    if onPeaks < onPeakNo
        output = nan;
        return
    end
    
    if dbPeaks < dbPeakNo
        output = nan;
        return
    end
    
%     figure(3);
%     clf;
%     subplot(3, 1, 1);
%     plot(raw);
%     subplot(3, 1, 2);
%     stairs(threshSignal, 'LineWidth', 2.0); 
%     legend(['on peaks: ', num2str(onPeaks), ' db-blink peaks: ', num2str(dbPeaks)])
%     subplot(3, 1, 3);
%     histogram(raw);
%     set(gca, 'YScale', 'log')
end

function [onPeaks, dbPeaks] = getpeakcount(signal)
    % this function determines the number of time signals crosses 0. It is
    % robust to the number of on states. Signal can have more than 1 on
    % states
    %
    % signal is the thresholded temporal barcode

    onPeaks = 0;
    dbPeaks = 0;
    
    % classification algorithm gives output from 1 and Inf. Change it to
    % start from 0
    signal = signal - 1;
    
    for iTime = 2:length(signal)
        if signal(iTime) == 0 && signal(iTime-1) == 1
            onPeaks = onPeaks + 1;
        elseif signal(iTime) == 0 && signal(iTime-1) > 1
            onPeaks = onPeaks + 1;
            dbPeaks = dbPeaks + 1;
        elseif signal(iTime) == 1 && signal(iTime-1) > 1
            dbPeaks = dbPeaks + 1;
        end
    end
end

function output = genOnOffStats2(barcode, expsrTime)
    % analyse the state chain to calculate # of on-peaks, on-time per
    % peak and off-time per peak. The signals will be analyzed for upto 3
    % states
    %
    % barcode is the state chain between 0 and 1 (eg. 0 0 0 0 1 2 2 1 0 1 0)
    % where each point is separated by expsrTime 
    %
    % expsrTime is the capture rate in seconds (eg. 0.1)
    barcode = barcode - 1;
    
    
    offTimes = [];
    onTimes = [];
    dbBlinkTimes = [];
    onPeaks = 0;
    
    onStart = 1;
    dbOnStart = 1;
    offStart = 1;
    for iTime = 2 : length(barcode)
        if barcode(iTime) == 1 && barcode(iTime-1) == 0
            offTimes = [offTimes; expsrTime * (iTime-offStart)];
            onStart = iTime;
            onPeaks = onPeaks + 1;
        elseif barcode(iTime) == 2 && barcode(iTime-1) == 0
            offTimes = [offTimes; expsrTime * (iTime-offStart)];
            onStart = iTime;
            dbOnStart = iTime;
            onPeaks = onPeaks + 1;
        elseif barcode(iTime) == 0 && barcode(iTime-1) == 1
            onTimes = [onTimes; expsrTime * (iTime-onStart)];
            offStart = iTime;
        elseif barcode(iTime) == 0 && barcode(iTime-1) == 2
            onTimes = [onTimes; expsrTime * (iTime-onStart)];
            dbBlinkTimes = [dbBlinkTimes; expsrTime * (iTime-dbOnStart)];
            offStart = iTime;
        elseif barcode(iTime) == 2 && barcode(iTime-1) == 1
            dbOnStart = iTime;
        elseif barcode(iTime) == 1 && barcode(iTime-1) == 2
            dbBlinkTimes = [dbBlinkTimes; expsrTime * (iTime-dbOnStart)];
        end
    end
    
    output = cell(4, 1);
    output{1} = onTimes;
    output{2} = dbBlinkTimes;
    output{3} = offTimes;
    output{4} = onPeaks;
    
%     figure(1); 
%     plot(barcode);
     fprintf(['\nmean on-time (s): ', num2str(median(onTimes)/log(2)), ' peaks #: '...
            num2str(onPeaks), ' median db-blink times(s): ',num2str(median(dbBlinkTimes)/log(2))]);
end

function output = applyhumanfilter(signal, raw)
    % filter signals due to high activity, drift, and any other unwanted
    % activity that was not removed by filter bank
    %
    % signal is the classified signal (eg. 0 0 0 0 1 1 2 1 1 0 0)
    %
    % raw is the intensity signature after simple corrections
    
    
    figure(4);
    clf;
    subplot(3, 1, 1);
    plot(raw);
    subplot(3, 1, 2);
    stairs(signal, 'LineWidth', 2.0); 
    subplot(3, 1, 3);
    histogram(raw);
    set(gca, 'YScale', 'log')
    
    genOnOffStats2(signal, 0.1);
    
    output = signal;
    hInput = input('\nkeep this signal [Y/N]?', 's');
    if hInput == 'N' || hInput == 'n'
        output = nan;
    end
end