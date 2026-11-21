clear
close all

f1=  'I:\Jibitesh\STED\150925\Control';

cl=0;
for cll=1:17 % Chhange as per number of cells 
    % cll=numb(clll);
    BW6=[];
  
 fs='';

f5=[fs num2str(cll,'%03d') '_1.tiff']; f6=[fs num2str(cll,'%03d') '_2.tiff'];
filename5=[f1 '/' f5];filename6=[f1 '/' f6];
 ThreshA=5; ThreshB=700;
I5a=imread(filename5);
I6a=imread(filename6);
imshow(I5a, []); colormap jet;
%%
for run=1:6
    % Chhange as per number of ROIs desired 
    BW6=[];
cl=cl+1;
figure (1)
imshow(I6a, []); colormap jet;
    r1 = drawrectangle('Label','Bck','Color',[1 0 0]);
    xstart=floor(r1.Position(2));
    xend=xstart+floor(r1.Position(4));
    ystart=floor(r1.Position(1));
    yend=ystart+floor(r1.Position(3));
   
    I5=I5a(xstart:xend,ystart:yend);
    I6=I6a(xstart:xend,ystart:yend);
c=0;

%% STED
for i=1:2
    
    
    if i==1 I3=I5;type="TFSTED";
    elseif i==2 I3=I6;type='TNFR1STED';
    end
    

 T = adaptthresh(I3, 0.6); %, 'NeighborhoodSize', 7);%was0.5
    % Convert image to binary image, specifying the threshold value.

    BW2 = imbinarize(I3,T);% imbinarize(I, T)
%     figure (2);imshow(BW2, []); title("Detected Pits"); %colormap jet; colorbar 

    se = strel('disk',1);BW2b=imfill(BW2,'holes');se2 = strel('disk',1);
    BW3b=imerode(BW2, se);BW3=imerode(BW3b, se);BW4=imdilate(BW3b, se2);BW5=imfill(BW4, 'holes');
    bw=BW5;
     figure (2)
     subplot(2,2,2*(i-1)+1);imshow(BW5, []);title(type)
     
 %%
%     D = bwdist(~bw);
% imshow(D,[])
% % title('Distance Transform of Binary Image')
%     D = -D;
% % imshow(D,[])
% % title('Complement of Distance Transform')
%     L = watershed(D);
% L(~bw) = 0;
    
    cc = bwconncomp(BW5); %was BW5
    stats = regionprops(cc,'Area','Eccentricity','PixelIdxList', 'centroid'); 
    idx = find(([stats.Area] > ThreshA) & ([stats.Area] <ThreshB)); % THRESH A 
BW = ismember(labelmatrix(cc),idx); LL=bwlabeln(BW); BW6(:,:,i)=BW;
% figure (3);
 subplot(2,2,2*i); imshow(BW, []); title(type)%colorbar; %title ("Labelled endosomes")
cc2 = bwconncomp(BW); 
% BWall(:,:,n)=BW;% BWall saves all teh particles detected
 stats2 = regionprops(LL,'Area','Eccentricity','PixelIdxList', 'BoundingBox','Centroid','Circularity');
% stats_AAA = regionprops('table',LL,'Area','Eccentricity','PixelIdxList', 'BoundingBox','Centroid','Circularity');
% statsall{n}=stats; % saves all teh stats
sLL=BW(BW==1);
if i==1 statsAP2s=stats2;totAAp2s(cl)=size(sLL,1);
    else statsCs =stats2;totCls(cl)=size(sLL,1);
end
end
 save([num2str(cl) fs 'statsstedn.mat'], 'statsAP2s','statsCs')
 %%

BW7=BW6(:,:,1)+BW6(:,:,2);
 figure(3)
BW9=BW7(BW7==2);
 imshow(BW7, [])
 imcontrast
colocAs(cl)=size(BW9,1);
colocAFs(cl)=size(BW9,1)/(size(BW,1)*size(BW,2));
colocAAp2s(cl)=100*size(BW9,1)/totAAp2s(cl);
colocCLs(cl)=100*size(BW9,1)/totCls(cl);
AFCLs(cl)=totCls(cl)/(size(BW,1)*size(BW,2));
AFAPs(cl)=totAAp2s(cl)/(size(BW,1)*size(BW,2));
BB(cl)=(size(BW,1)*size(BW,2));%sizeof ROI
end
end
%%
 save([num2str(cl) fs 'coloc28_new3.mat'], 'colocAFs','totAAp2s','totCls', 'AFCLs','AFAPs', 'colocAAp2s','colocCLs', 'colocAs')