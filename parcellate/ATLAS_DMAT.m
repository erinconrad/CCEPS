function D = ATLAS_DMAT(img)

% INPUTS:
% img: 3D matrix nifti image defining an atlas
%
% OUTPUTS:
% D: matrix of distances between centers of each parcel

nparc = length(unique(img(img~=0)));
coords = zeros(nparc,3);
for i = 1:nparc
    [xind,yind,zind] = ind2sub(size(img),find(ismember(img,i)));
    coords(i,:) = mean([xind,yind,zind],1);
end

D = squareform(pdist(coords,'Euclidean'));