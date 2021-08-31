function gl = obtain_global_network_measures(out)

%% Load BCT
locations = cceps_files;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.bct));

%% Only keep stim chs
A = out.A;
stim_chs = out.ch_info.stim_chs;
A = A(stim_chs,stim_chs);

%% Make nan entries zero and other entries 1 (binarize it)
A(isnan(A)) = 0;
A(A~=0) = 1;

%% Density
% the fraction of present connections to possible connections (ignores
% connection weights)
D = density_dir(A);

%% Transitivity
% the ratio of triangles to triplets in the network and is an alternative to the clustering coefficient.
T=transitivity_bd(A);

%% Modularity
% the degree to which the network may be subdivided into clearly delineated groups
% by default, gamma is 1
[~,Q]=modularity_dir(A);

%% Global efficiency
% the average inverse shortest path length in the network, and is inversely related to the characteristic path length
E=efficiency_bin(A);

%% output stuff
gl.name = out.name;
gl.chs = find(stim_chs);
gl.ch_labels = out.chLabels(stim_chs);
gl.n1.A = A;
gl.n1.waveform = 'N1';

gl.n1.measures.D.name = 'Density';
gl.n1.measures.D.data = D;

gl.n1.measures.T.name = 'Transitivity';
gl.n1.measures.T.data = T;

gl.n1.measures.Q.name = 'Modularity';
gl.n1.measures.Q.data = Q;

gl.n1.measures.E.name = 'Efficiency';
gl.n1.measures.E.data = E;

end