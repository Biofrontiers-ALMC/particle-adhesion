clearvars
clc

load('D:\Documents\OneDrive - UCB-O365\tmp\P2_A3_0114.mat');

%Try classifying particles by displacement?
isStatic = false(1, L.NumTracks);
isBound = false(1, L.NumTracks);

totalDistance = nan(1, L.NumTracks);
displacement = nan(1, L.NumTracks);
hullArea = nan(1, L.NumTracks);

for iP = 1:L.NumTracks
    
    ct = getTrack(L, iP);

    %Ignore any tracks that are too short
    if numel(ct.Frames) < 80
        continue
    elseif any(isnan(ct.Centroid(:, 1)))
        continue
    end

    %Calculate displacement
    diffDist = diff(ct.Centroid, 1, 1);
  
    frameDisplacement = sum((diff(ct.Centroid, 1, 1)).^2, 2);

    displacement(iP) = sum((ct.Centroid(1, :) - ct.Centroid(end, :)).^2, 2);

    [~, hullArea(iP)] = convhull(ct.Centroid);

    totalDistance(iP) = sum(frameDisplacement);
    
    if hullArea(iP) < 20

        isStatic(iP) = true;

    elseif hullArea(iP) < 100

        isBound(iP) = true;

    end

    %Use convex hull to get area traversed?

end

find(isStatic)
find(isBound)