clearvars
clc

reader = BioformatsImage('F:\trese\P2_A3_0114.nd2');

%%

[~, fn] = fileparts(reader.filename);

L = LAPLinker;
L.LinkScoreRange = [0 20];

vid = VideoWriter([fn, '.avi']);
vid.FrameRate = 5;
open(vid)

for iT = 1:reader.sizeT

    %Get the particle image
    Iparticle = getPlane(reader, 1, 2, iT);

    %Mask the particles

    %Calculate the difference of Gaussians
    dg1 = imgaussfilt(Iparticle, 3);
    dg2 = imgaussfilt(Iparticle, 6);

    dog = dg1 - dg2;

    %Mask the spots
    mask = dog > 3000;
    mask = bwareaopen(mask, 2);

    % mask = bwareaopen(mask, ip.Results.minSpotArea);
    mask = bwmorph(mask, 'hbreak');

    particleData = regionprops(mask, 'Centroid');

    %Track particles
    L = assignToTrack(L, iT, particleData);

    Icell = getPlane(reader, 1, 3, iT);

    Iout = double(Iparticle);
    Iout = (Iout - min(Iout(:)))/(max(Iout(:))-min(Iout(:)));

    Icell = double(Icell);
    Icell = (Icell - min(Icell(:)))/(max(Icell(:))-min(Icell(:)));

    Iout = cat(3, Iout, Icell, Iout);
    
    for ii = L.activeTrackIDs

        ct = getTrack(L, ii);

        if ~isnan(ct.Centroid(end, 1))

            Iout = insertShape(Iout, 'filled-circle', ...
                [ct.Centroid(end, 1), ct.Centroid(end, 2), 2], ...
                'ShapeColor', 'white');

            Iout = insertText(Iout, [ct.Centroid(end, 1), ct.Centroid(end, 2)], ...
                int2str(ii), 'BoxOpacity', 0, 'TextColor', 'yellow', ...
                'AnchorPoint', 'CenterTop');
        end

        if numel(ct.Frames) > 1
            try
                Iout = insertShape(Iout, 'line', ct.Centroid, ...
                    'ShapeColor', 'white');
            catch
                continue
                %Happens if centroid contains NaNs
            end
        end

    end


    %Make output video
    writeVideo(vid, Iout)

    

end
close(vid)

imshowpair(Iparticle, mask)

save([fn, '.mat'], 'L')

% 
% 
% 
% function mask = identifySpots(I, expansionFactor, varargin)
%             %IDENTIFYSPOTS  Segment spots using difference of Gaussians
%             %
%             %  M = IDENTIFYSPOTS(I, EX) creates a mask M of spots using the
%             %  difference of Gaussians filter. To improve accuracy of
%             %  finding the spots, the image I is expanded by the factor EX.
%             %  Note that the corresponding output mask is also expanded by
%             %  the same factor and this needs to be taken into account in
%             %  forward measurements.
%             %
%             %  M = IDENTIFYSPOTS(..., Parameter, Value) allows the
%             %  following parameter/value pairs to be used to change the
%             %  behavior of the spot finding algorithm.
%             %
%             %  * 'spotRange' allows the size of the spots to be set. The
%             %    default range is [3, 8] pixels. Note that this is the size
%             %    of the spots PRIOR to expansion.
%             %  * 'spotThreshold' 
%             %
%             %  
% 
%             %Parse the input
%             ip = inputParser;
%             addParameter(ip, 'spotRange', [3 8]);
%             addParameter(ip, 'spotThreshold', 15);
%             addParameter(ip, 'applyWatershed', true);
%             addParameter(ip, 'minSpotArea', 30);
%             parse(ip, varargin{:})
% 
%             %Post-process the image
%             I = medfilt2(I, [3 3]);
% 
%             %Expand image to make it easier to identify particles
%             I = imresize(I, expansionFactor, 'nearest');
% 
%             %Calculate the difference of Gaussians
%             dg1 = imgaussfilt(I, min(ip.Results.spotRange));
%             dg2 = imgaussfilt(I, max(ip.Results.spotRange));
% 
%             dog = dg1 - dg2;
% 
%             %Mask the spots
%             mask = dog > ip.Results.spotThreshold;
%             mask = bwareaopen(mask, 2);
% 
%             if ip.Results.applyWatershed
% 
%                 regMax = imregionalmax(I, 8);
%                 regMax(~mask) = false;
% 
%                 regMax = imdilate(regMax, strel('disk', 2));
%                 regMax = bwmorph(regMax, 'hbreak', 1);
%                 regMax = bwmorph(regMax, 'shrink', Inf);
% 
%                 dd = -bwdist(~mask);
%                 dd(~mask) = -Inf;
%                 dd = imhmin(dd, 1);
% 
%                 dd = imimposemin(dd, regMax);
% 
%                 L = watershed(dd);
% 
%                 mask(L == 0) = false;
%             end
% 
%             mask = bwareaopen(mask, ip.Results.minSpotArea);
%             mask = bwmorph(mask, 'hbreak');
% 
%             %imshow(mask, 'InitialMagnification', 400)
% 
%         end