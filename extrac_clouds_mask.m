function [ BW2 ] = extrac_clouds_mask( shadowMap )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    mean_SM = mean( mean( shadowMap));
    std_SM = std( std( shadowMap));
    % mask creation and fill it
    mask_SHW = ones( size( shadowMap));
    mask_SHW ( find( shadowMap <= (mean_SM + std_SM))) = 0;
    BW2 = bwareaopen(mask_SHW, 4000);
    BW2 = rangefilt(shadowMap);
    figure
    imshowpair(mask_SHW,BW2,'montage')
end

