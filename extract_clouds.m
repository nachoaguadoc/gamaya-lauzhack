%Load data from LauzHack format
%hyperIm = imread('OrthoVNIR.tif');
%hyperIm = hyperIm(3000:5000,1:3000,:); % Reduce image size if you experience RAM issues
clear all;
close all;
hyperIm = imread('ortho.tif');
%hyperIm = hyperIm(1:1000, 1500:3000, :);
%hyperIm = hyperIm(1:1000, 1:1000, :);
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
figure;
imshow(rgb);
hold on;
plot(669, 691, '*r')
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
%figure;
%plot(reshape(refl(920, 1973, :),[41, 1, 1]).');
%hold on;
%plot(reshape(refl(1033, 2068, :),[41, 1, 1]).');
%reshape(refl(1201, 2083, :), [41, 1, 1]).'; % Tierra con sol
pixels = [669 691; 1184 157 ; 352 1214 ];
% I wanna die.
materials = [];
for i=1:size(pixels,1)
    a = reshape(refl(pixels(i,1), pixels(i,2), :), [41, 1, 1]).';
    [W H D] = size(refl);
    class_m = zeros(W,H);
    
    for w = 1:W
       for h = 1:H
           matrix_cc = corrcoef(a, reshape(refl(w, h, :),[41, 1, 1]).');
           if  matrix_cc(2,1) > 0.99
               class_m(w, h) = 1;
           end       
       end
    end
    materials(:,:,i) = class_m;
    figure;
    subplot(2,2,i)
    imshow(class_m * 100);
    hold on;
    plot(pixels(i,1), pixels(i,2), '*r');
    legend('Mucha', 'Poca', 'Nada/SOL :D');
end

%% 


image_mask = extrac_clouds_mask(shadowMap);
cloudy_points = zeros(size(materials));
sunny_points = zeros(size(materials));

for i=1:size(materials,3)
    cloudy_points(:,:,i) = image_mask & materials(:,:,i);
    sunny_points(:,:,i) = ~image_mask == 0 & materials(:,:,i) == 1
end
%% 
spectrum_sunny = zeros(size(refl,3),size(materials,3));
spectrum_cloudy = zeros(size(refl,3),size(materials,3));

for i=1:size(materials,3)
    for j=1:size(refl,3)
        spectrum_sunny(j,i) = mean2(refl(:,:,j).*sunny_points(:,:,i));
        spectrum_cloudy(j,i) = mean2(refl(:,:,j).*cloudy_points(:,:,i));
    end
end

%% 
first = zeros(41,1);
second = zeros(41,1);
for i=1:size(cloudy_points ,1)
    for j=1:size(cloudy_points,2)
        if (cloudy_points(i,j,1)==1)
            if (any(first))
                second(:) = refl(i,j,:);
                break
            else
                first(:) = refl(i,j,:);
            end
        end
    end
end

A = [first -second];
B = ones(41,1).*0.0001;
X = A\B
%% 

T = first/X(1)
T = T./spectrum_sunny(:,1)
%% 

for i=1:size(materials,3)
    T = spectrum_sunny(:,i) - spectrum_cloudy(:,i);
    for j=1:size(refl,3)
        refl = refl(refl(:,:,j)&cloudy_points(:,:,i))+T(j);
    end
end
figure;
imshow(refl(:,:,[16 8 2]));