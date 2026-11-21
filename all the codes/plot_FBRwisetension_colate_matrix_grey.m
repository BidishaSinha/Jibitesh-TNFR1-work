Allfilenames=uigetfile({'*.mat'},'Select all matfiles to work woth','MultiSelect','On');
[rr ncells]=size(Allfilenames);loadten='n';Tenall=[];
for nn=1:ncells
 clearvars -except Tenall SDs_all SDt_all Conall Visall Acall Allfilenames rr ncells nn Ten_c SDsc SDtc Con_c  Vis_c Ac_c 
 name=Allfilenames{nn};filename = name
 load(filename);
  Tenall = [Tenall; fbrTen(:,2)];
 fbrsize=12; %2x2
map_lower_lim = 0;
map_upper_lim = 200;
close all
[row,col]=size(FBinM3);
Tenmap=zeros(row, col);
for i=1:length(fbrRS)
    id=fbrRS(i,1);
    x=FBR(id,1);
    y=FBR(id,2);
    Tenmap(x:x+fbrsize-1, y:y+fbrsize-1)=fbrTen(i,2);
end
cm = [0.5 0.5 0.5; jet(map_upper_lim - map_lower_lim - 1)];
bb = mat2gray(Tenmap, [0 100]);
cc = gray2ind(bb, map_upper_lim);
dd = ind2rgb(cc, cm);
imshow(dd);
imwrite(dd,[ filename,'.tif']);
end