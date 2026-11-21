
%%
f = fullfile("G:\IRM\110322\plate1\Exported\Control\005\set\" ,"*.tif"); %% change accordingly   ******** important change it
list = dir(f);
Nstart = 1 ;
Nend= length(list);
cc = 0;
conv=34.08807;
Inmin=902.96698;
xstart=60;
ystart=296;
xend=xstart+11;yend=ystart+11;
for i=Nstart:Nend
    cc=cc+1;
    list(i).name;
    A=double(imread(fullfile(list(i).folder,list(i).name)));
    Im2(:,:,cc)=(A(xstart:xend, ystart:yend)-Inmin)./conv;
    Im(:,:,cc)=A(xstart:xend, ystart:yend);
end

% FBinM3=FBinM2;%imshow(IrgbM, []);
A=A(xstart:xend,ystart:yend);
[row col]=size(A);
F4=double(zeros(row,col));
close;

%% OVERLAY FBRs
% Imstd=std(single(Im2), [],3);
for iii = 1:length(FBR)
    x_fbr = FBR(iii,1);
    y_fbr = FBR(iii,2);
    AAA(:,:,iii) = Im2(x_fbr:x_fbr+M-1,y_fbr:y_fbr+N-1);
end
%%
clearvars -except AAA val FBR
for i11=1:length(FBR)
    for i12=1:length(val)
        pos_fit = val(i12);
        AAA_new(:,:,i12) = AAA(:,:,pos_fit);
    end
end
[aa bb cc] = size(AAA_new);
tot = aa*bb*cc;
l1 = 0;
for i1=1:aa
    for j1=1:bb
        for k1=1:cc
            l1 = l1 + 1;
            AAA_tot(l1,:) = AAA_new(i1,j1,k1);
        end
    end
end
%surf(AAA_new(:,:,20)); colorbar;
save("010.mat",'AAA_new','FBR','val','AAA_tot')
%%
%for plotting
for jj1 = 1:length(A)
    x(jj1,:) = jj1*180;
    y(jj1,:) = jj1*180;
end
surf(x,y,Im2(:,:,20)); colorbar; title("surface plot")
%save("001.mat",'AAA_new','FBR','val')
%save("009.mat",'AAA','FBR')
%%
for ii=1:Nend
    AAA(ii,:)=Im2(1,1,ii);
    t(ii,:)=ii*0.05;
    
end
plot(t,AAA)

