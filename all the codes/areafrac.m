clear;
I = imread('H:\Jibitesh\TIRF\291024\TNFa2\TNFa_038.tif');
imtool(I,[])
Iblur = imgaussfilt(I,10);
denoisedImage = (I - Iblur);
normImage1 = mat2gray(denoisedImage);
BW1 = im2bw(normImage1,0.03);%% change here
imtool(BW1)
roi = regionprops('table',BW1,'Centroid');
%%
%output = imgaussfilt(I,8);                                 
%normImage = mat2gray(output);
%BW = im2bw(normImage,0.09);
%imtool(BW)
%mask = boundarymask(BW);
%%
[sROI] = ReadImageJROI('H:\Jibitesh\TIRF\291024\TNFa2\c38.roi');
sROI;
T = struct2cell(sROI);
M = cell2mat(T(7));
x = M(:,1);
y = M(:,2);
BW = roipoly(I,x,y);
imtool(BW)
bmask = boundarymask(BW);
%imtool(labeloverlay(BW,bmask,'Transparency',0))
%imtool(imfuse(bmask,I))
%%
% above allover roi is found
% clearing paricles outside mask
ROI_sel = BW1;
ROI_sel(BW == 0) = 0;
imtool(ROI_sel)
SE = strel("disk",1);
a1 = imerode(ROI_sel,SE);
b1 = imdilate(a1,SE);
%b1 = imdilate(ROI_sel,SE);
%imtool(b1)
imtool(imfuse(bmask,b1))
%%
roi_actual = regionprops('table',b1,'Centroid');
roi_area_cen = regionprops('table',b1,'area','Centroid','Circularity');
[x,t] = size(roi_actual);
% selected roi is found out,next we have to calculate the area
[m,n] = size(BW);
count = 0;
for i = 1 : m
    for j = 1 : n
        if BW(i,j) == 1
         count = count + 1;
        end
    end
end
Total_area_of_cell = count*(0.065*0.065);
Number_density = (x/Total_area_of_cell);
% Number density has been found now letz calulate area density
[m1,n1] = size(ROI_sel);
count1 = 0;
for k = 1 : m1
    for l = 1 : n1
        if ROI_sel(k,l) == 1
         count1 = count1 + 1;
        end
    end
end
Area_density = count1/count;
props = regionprops(b1, I, 'MeanIntensity');
allIntensities = [props.MeanIntensity];% for mean intensity
% for finding the average distance between rois'
% converting table to array first
A_roi = table2array(roi_area_cen);
A = table2array(roi_actual);
[m2,n2] = size(A);
D = pdist(A);
[t1,t2] = size(D);
Sum1 = (sum(D));
Av_dist_px = (Sum1/t2);
Av_dist_um = Av_dist_px * 0.065;
dist_px = min_dist(A_roi(:,2:3));
Min_av_dis = (dist_px*0.065);
Median_circularity = median(A_roi(:,4));

save('c38.mat')
% for saving the rois selected
fid = fopen('c38.txt','wt');
for ii = 1:size(A_roi,1)
    fprintf(fid,'%g\t',A_roi(ii,:));
    fprintf(fid,'\n');
end
fclose(fid);
Number_density
Area_density
Min_av_dis
Median_circularity
Total_area_of_cell
%%
