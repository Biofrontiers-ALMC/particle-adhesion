clearvars
clc

load test.mat

%Try classifying particles by displacement?
for iP = 1:NumTracks
    
    ct = getTrack(L, iP);

    %Filter any tracks that are too short
    if numel(ct.Frames) < 80
        continue
    end

    




end