% This code helps you analyze a movie of Tf. The last frame is used as a refernce. 
% objects are detected. centring on centroids, 13 pixel linescan in
% performed and kymograph built for each such puncta. 
% ThreshA is the threshold of pixels in objects for considering them as
% puncta.
% Thresh is the minimum mean intensity to consider a timepoint in a
% particular puncta-kymograph as a puncta
clear
endc=[];
conn=1;con='TNFR1';sncell=1; 



close all
% olddir=cd('/Users/bidishasinha/Data/sample data');
cd('L:\Jibitesh\IRM\04062025\Plate1\Exported\Before_after\002');
load('L:\Jibitesh\IRM\04062025\Plate1\Exported\Before_after\002\BAAAna002-01Cell_01.mat', 'IrgbM','xstart','xend','ystart','yend', 'FBR', 'fbrTen', 'SDs', 'SDt')
mask=(65535-IrgbM(:,:,1)).*(65535-IrgbM(:,:,2));

for kk=1:2
    if kk==1 olddir=imread('L:\Jibitesh\IRM\04062025\Plate1\Exported\Before_after\002\003.tif');
    else imread('L:\Jibitesh\IRM\04062025\Plate1\Exported\Before_after\002\004.tif')
    end

    
endc=[];

GETALLCEN='n';% put n if running the cell for first time.
clc
close all

ThreshA=10; ThreshB=5000; thresh=200;


A=dir('*.tif');
% nframes=size(A,1); 
%frametostart=nframes; 
nframes=1; % actually nframes are the number of frames used in teh analyses
% nframes=30;
for i=1:nframes
    if kk==1 offset= 1-nframes; % change the 200 if needed. it is the total number of frames in teh before TIRF folder
        elseoffset=0;
    end
    filename=A(i+offset).name;
  Iold(:,:,i)=imread(filename);
end



I=Iold(xstart:xend, ystart:yend, :); % from IRM imported
% imagesc(I(:,:,1)); title ('Draw Boundary of Cell')
%     h = imfreehand;
%     BW = createMask(h);

%% GET ALL CENTROIDS OR read centroids
 sfname = [con '_ALLSTATS_' num2str(sncell) '_tillframe_' num2str(nframes) '.mat']; % change this for every ROI

if GETALLCEN=='n' % put y if running the cell for first time.
for i =1 : nframes
    I3=I(:,:,i);
    T = adaptthresh(I3, 0.3); % you may need to change this
    BW2 = imbinarize(I3,T);
    % T = adaptthresh(I3, 0.4); 
    % Convert image to binary image, specifying the threshold value.

    BW2 = imbinarize(I3,T);% imbinarize(I, T)
     % figure (2);imshow(BW2, []); title("Detected Pits"); %colormap jet; colorbar 
 
    se = strel('disk',1);BW2b=imfill(BW2,'holes');se2 = strel('disk',1);
    BW3=imerode(BW2b, se);BW4=imdilate(BW3, se2);BW5=imfill(BW4, 'holes');
    % bw=BW5.*BW.*mask;
    BW=mask/max(mask(:)); % to overlay IRM mask on TIRF
    bw=BW5.*BW;
    Ibw(:,:,i)=bw; %3D fial mask including objects detected
    doD='n';
    
        cc=bwconncomp(bw);
    
    stats = regionprops(cc,'Area','Eccentricity','PixelIdxList', 'centroid'); 
    
    sizestats=size(stats);
    if sizestats(1)>0 
        uc=0;
        for u=1:sizestats(1)
        IntPixels=stats(u).PixelIdxList;Int=mean(mean((I3(IntPixels))));
        stats(u).Intensity = Int;cen=stats(u).Centroid; 
        stats(u).XC=cen(1);stats(u).YC=cen(2);
        end
    end
    idx = find(([stats.Area] > ThreshA) & ([stats.Area] <ThreshB) & ([stats.Intensity] >thresh)); % THRESH A 
    BWw = ismember(labelmatrix(cc),idx); LL=bwlabeln(BWw);
     figure (3); imshow(LL, []); colormap jet;  %title ("Labelled endosomes")
     stats2 = regionprops(LL,'Area','Eccentricity','PixelIdxList', 'centroid'); 

       sizestats=size(stats2);
    if sizestats(1)>0 
        uc=0;
        for u=1:sizestats(1)
        IntPixels=stats2(u).PixelIdxList;Int=double(mean(mean((I3(IntPixels)))));
        stats2(u).Intensity = Int;cen=stats2(u).Centroid; 
        stats2(u).XC=cen(1);stats2(u).YC=cen(2);
        end
    end

    Allstats{i}=stats2;
    % idx = find(([stats.Area] > ThreshA) & ([stats.Area] <ThreshB) & ([stats.Intensity] >thresh)); % THRESH A 
    % BW = ismember(labelmatrix(cc),idx); LL=bwlabeln(BW);
    % figure (3); imshow(LL, []); colormap jet; colorbar; title ("Labelled endosomes")
    % 
 end

save(sfname)
else

load(sfname)
end

 %% Choose an ROI
 % I2=Ibw; %I(:,:,nframes);
 
 I33=I;
nslot=nframes;run=1;

% szshl=zeros(nframes/nslot);
 
kimst=[];kimsti=[];
clearvars -except SDt SDs offset FBR fbrTen kk mask Inewbefore BW Allstats szshl Ibw I33 xstart xend nslot ystart yend thresh ThreshA ThreshB BI endc sfname run nframes frametostart dirname1 str I LL ncells conn con str olddir dirr dirname1 sncell 
I3=I(:,:, (run-1)*nslot+nframes);

Inew=sum(Ibw, 3); % sum of 3D of object deted
      

%% get centroid automaticaaly
% xstart=1;ystart=1;xend=size(I,2);yend=size(I,1);
    
    sizest=size(Allstats{(run-1)*nslot+nframes});
    np=sizest(1);

    S=Allstats{(run-1)*nslot+nframes}; % reading first frame of slots
     idx=find((([S.XC]>(ystart+6)) & ([S.XC]<(yend-6))) & (([S.YC]>(xstart+6)) & ([S.YC]<(xend+6))));
     % ([stats.Area] > ThreshA) & ([stats.Area] <ThreshB) & ([stats.Intensity] >thresh)
    % idx=find(([S.XC]>(ystart+6)& ([S.XC]<(yend-6))));

    sizest=size(idx);
    np=sizest(2);
%%
npcc=0;innp=[];
for i1=1:np
    px(i1)=int16(S(idx(i1)).XC); py(i1)=int16(S(idx(i1)).YC);
    Intparticle(i1)=S(idx(i1)).Intensity;
    Areaparticle(i1)=S(idx(i1)).Area;
    check=Inew(py(i1), px(i1));
    if check > 0.85*nframes && Intparticle(i1)>thresh % you may change intparticle threhold of needed
        npcc=npcc+1;
        innp(npcc)=i1;
        if kk==1
        pxcc1(npcc)=px(i1);pycc1(npcc)=py(i1);
        else
            pxcc2(npcc)=px(i1);pycc2(npcc)=py(i1);
        end
    end
end
if kk==1
        Inewbefore=Inew;
        else
            Inewafter=Inew;
        end

%% get kymo along x
clear kim; clear kimst;

npc=0;
for j= 1:np
    
    % if (px(j)-6 >=1) && (px(j)+6 <= yend-ystart+1) && (py(j)-6 >=1) && (py(j)+6 <= xend-xstart+1) && (Intparticle(j)>=thresh)
        npc=npc+1;
    for i= 1:nslot 
    I33b=Ibw(:,:,(run-1)*nslot+i);%%%%%%%
    I33c=double(I33(:,:,(run-1)*nslot+i));
kim(i, :, npc)=I33b(py(j), px(j)-6:px(j)+6);
kimi(i, :, npc)=I33c(py(j), px(j)-6:px(j)+6);
    px(j) = round(px(j));
py(j) = round(py(j));

H = size(I33b,1);
W = size(I33b,2);

y1 = max(py(j)-6, 1);
y2 = min(py(j)+6, H);
x1 = max(px(j)-6, 1);
x2 = min(px(j)+6, W);

ykim = I33b(y1:y2, x1:x2);
    Si=Allstats{i};idxk=find(([Si.XC]>px(j)-6) & ([Si.XC]<px(j)+6) & ([Si.YC]>py(j)-6) & ([Si.YC]<py(j)+6));
    sizeidx=size(idxk); 
     uc=0;
    if sizeidx(2)>0 
        pardec=1;
        else pardec=0;
    end
    % kim2{j}=I33(px(j)-6:px(j)+6, px(j)-6:px(j)+6,:);
    npk(i, npc)=pardec;

    % Ikim(i,npc)=mean(I33b(py(j), px(j)-6:px(j)+6));
    Ikim(i,npc)=I33b(py(j), px(j));
    end
    
    
end
    %% SET tHRESHOLD to get at time at a region and get "lifetime" along the kymograph
    clear y; clear kimst;
    


%% number of stuck puncta2
nstuck2=0;kimst2=[];kimsti=[];kimst3=[];ten=[];nstuck3=0;nstuck4=0;mind1=10000;mind2=10000;
for i=1:np
    if kk==2
check2=Inewbefore(py(i), px(i));
    else check2= 100000;
    end
if min(size(innp(innp==i)))>0 && check2>0.85*nframes
    nstuck2=nstuck2+1;
    kimst2=[kimst2,kimi(:,:,i),zeros(nslot, 16)];
    kimst3=[kimst3,i*kim(:,:,i),zeros(nslot, 16)];

    if kk==2
    for ff=1:size(fbrTen, 1)
    fn=fbrTen(ff, 1);
    mind1=min(mind1, py(i)-FBR(fn, 1));mind2=min(mind2, py(i)-FBR(fn, 2));
    
    if py(i)>=FBR(fn, 1) && py(i)<=FBR(fn, 1)+FBR(fn, 3) && px(i)>=FBR(fn, 2) && px(i)<=FBR(fn, 2)+FBR(fn, 4)
    nstuck3=nstuck3+1;
        ten(nstuck3)=fbrTen(ff, 2);
        intstuck(nstuck3)=Intparticle(i);
        areastuck(nstuck3)=Areaparticle(i);
    end
    end
    
    for ff2=1:size(SDt, 1)
    fn=SDt(ff2, 1);
    mind1=min(mind1, py(i)-FBR(fn, 1));mind2=min(mind2, py(i)-FBR(fn, 2));
    
    if py(i)>=FBR(fn, 1) && py(i)<=FBR(fn, 1)+FBR(fn, 3) && px(i)>=FBR(fn, 2) && px(i)<=FBR(fn, 2)+FBR(fn, 4)
    nstuck4=nstuck4+1;
        sdt(nstuck4)=SDt(ff2, 2);sds(nstuck4)=SDs(ff2, 2);
        intstuckb(nstuck4)=Intparticle(i);
        areastuckb(nstuck4)=Areaparticle(i);
    end
    end



    end



end
kimsti=[kimsti,kimi(:,:,i),zeros(nslot, 16)];
end
figure (4); imshow(kimst3, []); colormap jet; colorbar; title("color coded stuck kymo")
figure (5); imshow(kimsti, []); colormap jet; colorbar; title("all kymo")


end

%%

[rho, p]=corrcoef(ten, intstuck)
figure (6);subplot(3,3,1);plot(intstuck, ten, 'o'); title(["rho " num2str(rho(1,2)) "   p " num2str(p(1,2))]);xlabel("Mean cluster intensity (au)"); ylabel("FBR tension of cluster centroid (pN/um)")

[rhoa, pa]=corrcoef(ten, intstuck.*areastuck)
subplot(3,3,2);plot(intstuck.*areastuck, ten, 'o'); title(["rho " num2str(rhoa(1,2)) "   p " num2str(pa(1,2))]);xlabel("Tot int (au)"); ylabel("FBR tension of cluster centroid (pN/um)")


[rhoa, pa]=corrcoef(ten, areastuck)
subplot(3,3,3);plot(areastuck, ten, 'o'); title(["rho " num2str(rhoa(1,2)) "   p " num2str(pa(1,2))]);xlabel("Cluster area (au)"); ylabel("FBR tension of cluster centroid (pN/um)")

% figure(8)
% plot(areastuck, intstuck, 'o')

[rho, p]=corrcoef(sdt, intstuckb)
subplot(3,3,4);plot(intstuckb, sdt, 'o'); title(["rho " num2str(rho(1,2)) "   p " num2str(p(1,2))]);xlabel("Mean cluster intensity (au)"); ylabel("FBR sdt of cluster centroid (nm)")

[rhoa, pa]=corrcoef(sdt, intstuckb.*areastuckb)
subplot(3,3,5);plot(intstuckb.*areastuckb, sdt, 'o'); title(["rho " num2str(rhoa(1,2)) "   p " num2str(pa(1,2))]);xlabel("Tot int (au)"); ylabel("FBR sdt of cluster centroid (nm)")


[rhoa, pa]=corrcoef(sdt, areastuckb)
subplot(3,3,6);plot(areastuckb, sdt, 'o'); title(["rho " num2str(rhoa(1,2)) "   p " num2str(pa(1,2))]);xlabel("Cluster area (au)"); ylabel("FBR sdt of cluster centroid (nm)")

[rho, p]=corrcoef(sds, intstuckb)
subplot(3,3,7);plot(intstuckb, sds, 'o'); title(["rho " num2str(rho(1,2)) "   p " num2str(p(1,2))]);xlabel("Mean cluster intensity (au)"); ylabel("FBR sds of cluster centroid (nm)")

[rhoa, pa]=corrcoef(sds, intstuckb.*areastuckb)
subplot(3,3,8);plot(intstuckb.*areastuckb, sds, 'o'); title(["rho " num2str(rhoa(1,2)) "   p " num2str(pa(1,2))]);xlabel("Tot int (au)"); ylabel("FBR sds of cluster centroid (nm)")


[rhoa, pa]=corrcoef(sds, areastuckb)
subplot(3,3,9);plot(areastuckb, sds, 'o'); title(["rho " num2str(rhoa(1,2)) "   p " num2str(pa(1,2))]);xlabel("Cluster area (au)"); ylabel("FBR sds of cluster centroid (nm)")

save('TNFR1_full_workspace_001.mat')