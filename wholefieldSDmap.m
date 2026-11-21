clear
dirname='K:\Jibitesh\IRM\31052025\Plate1\Exported\002\Set';
old_dir=cd(dirname)
list=dir('*.tif');
nfiles=length(list);
inmin=3386.28017;conv=32.64734;

for n=1:2048
     
A1=imread(list(n).name);
A=double(A1);
Im(:,:,n)=double((A-inmin)./conv);
% imshow(A, []);
end
imstd=std(Im,0,3);
imshow(imstd, [2 7]); colormap jet; colorbar
cd(old_dir)