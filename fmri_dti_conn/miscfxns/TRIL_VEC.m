function edges = TRIL_VEC(A)

% INPUTS:
% A: NxN matrix
% 
% OUTPUTS:
% edges: lower triangle edges in an N*(N-1)/2 vector

N=length(A);
edges = A(~~tril(ones(N)) & ~eye(N));