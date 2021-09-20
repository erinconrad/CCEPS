function edges = OFFDIAG_VEC(A)

% INPUTS:
% A: NxN matrix
% 
% OUTPUTS:
% edges: off-diagonal triangle edges in an N*(N-1)x1 vector

N=length(A);
edges = A(~eye(N));