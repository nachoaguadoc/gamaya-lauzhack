%This function apply kmeans to the image.
function [img_out] = kmeans_segmentation(img, k)
    flatImg = double(reshape(img,size(img,1)*size(img,2),size(img,3))); %reshape the image.
    idx = kmeans(flatImg,k,'emptyaction','singleton')
    flatImg
    size(idx)
    size(img,1)*size(img,2)
    img_out = reshape(idx,size(img,1),size(img,2)); %reshape image again to convert in image.
    img_out = double(img_out/max(max(img_out))); %normalize the image.
end

