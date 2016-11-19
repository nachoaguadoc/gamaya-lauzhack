%Load data from LauzHack format
%hyperIm = imread('OrthoVNIR.tif');
%hyperIm = hyperIm(3000:5000,1:3000,:); % Reduce image size if you experience RAM issues
clear all;
close all;
hyperIm = imread('ortho.tif');
% First channel in monochromatic in the 470-650 nm range
panChannel = hyperIm(:,:,1);
% Image coming from the VIS camera 470-650 nm
visIm = hyperIm(:,:,2:17);
% Image coming from the NIR camera 650-950 nm
nirIm = hyperIm(:,:,18:42);
% alpha channel of the image
alpha = hyperIm(:,:,43);
clear('hyperIm');
%% Regroup VIS and NIR images into reflectance structure, convert alpha to logical
refl = single(cat(3, visIm, nirIm));
alpha = alpha > 0;
clear('visIm','nirIm');
%hyper.refl = bsxfun(@rdivide, hyper.refl, max(max(hyper.refl)));
% Scale integer data to 0..1 reflectance range
refl = (refl - min(refl(:))) / (max(refl(:)) - min(refl(:)));

%% Compute RGB, extract Refl size
rgb = refl(:,:,[16 8 2]);
rgb(:) = imadjust(rgb(:),stretchlim(rgb(:),[.01 .99]));
[N M B] = size(refl);

%% Generate shadow map
% Currently computed as geometric mean of channels
shadowMap = ones([N M]);
visShadowMap = shadowMap;
for b = 1:B
    shadowMap = shadowMap .* (1-refl(:,:,b)) ;
end
% Normalize shadow map between 0..1
aux = shadowMap(alpha).^(1/B);
shadowMap(alpha) = imadjust(aux,stretchlim(aux,[.1 .9999])); %Clouds are white

%%  1st way: Mean for the selection area
image_mask = extrac_clouds_mask( shadowMap );
