% IF continuing after a longtime
Allfilenames=uigetfile({'*.mat'},'Select all matfiles to work woth','MultiSelect','On');
[rr ncells]=size(Allfilenames);loadten='n';Tenall=[]; SDs_all=[]; SDt_all=[];Ten_c = [];SDsc = [];SDtc = [];
Conall=[]; Con_c=[];  Vis_c=[]; Visall=[]; Ac_c=[]; Acall=[];
%%
for nn=1:ncells 
 clearvars -except Tenall SDs_all SDt_all Conall Visall Acall Allfilenames rr ncells nn Ten_c SDsc SDtc Con_c  Vis_c Ac_c 
 name=Allfilenames{nn};filename = name
 load(filename);
 Tenall = [Tenall; fbrTen(:,2)];
 SDs_all = [SDs_all; SDs(:,2)];
 SDt_all = [SDt_all; SDt(:,2)];
 Conall = [Conall; fbrC(:,2)];
 Visall = [Visall; fbrV(:,2)];
 Acall = [Acall; fbrAc(:,2)];
 Ten_c = [Ten_c;median(fbrTen(:,2))];
 SDsc = [SDsc;median(SDs(:,2))];
 SDtc = [SDtc;median(SDt(:,2))];
 Con_c = [Con_c;median(fbrC(:,2))];
 Vis_c = [Vis_c;median(fbrV(:,2))];
 Ac_c = [Ac_c;median(fbrAc(:,2))];
end
%%
save('ct2a.mat','Tenall','SDs_all','SDt_all','Ten_c','SDsc','SDtc','Conall','Con_c','Vis_c', 'Ac_c','Visall', 'Acall')