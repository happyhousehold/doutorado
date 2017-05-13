clear all;
clc;
%%
% MIMO Channel 
N = 100;                  % number of antennas
F = fft(eye(N));          % Fourier Basis
g = exp(-0.6*(0:N-1)');   % Sparse representation

h = F*g;

K = sum(find(g>=0.01));  % Number of non-zero entries

% Comments: The channel "h" has a structured model. You can
% insert more realistics channel models.

% Pilot sequence 
M = ceil(1.001*K);                          % Length of the training sequence
P = 1/sqrt(2)*(randn(M,N) + 1i*randn(M,N));
% Comments : The matix P addresses pilot sequences to each antenna. 
 

s = P*h;                           % Transmit signal

% noise
sigma = 0.1;
noise = sqrt(sigma/2)*(randn(size(s))+1i*randn(size(s)));


% receive signal
x = s + noise;


% Estimation of g
[g_est] = omp(P*F,x,K);

% Comments: The performance of OMP depends on the choice of F and P. In
% this example, I assume that the channel has Fourier structure. In more
% realistic channel problem, Fourier basis presents a power leakage which
% increases the number of non-zero entries of g. Therefore, the choice of
% the F impacts directly on the algorithm performance.

% You can add an input 'opt' in omp(A,x,K,opt). 

%   'opt'  is a structure with more options, including:
%       .target     = Define a residual in case you do not have knowladge
%                     of the sparsity.
%       .mode   = {0,1};  
%       If mode=0, there is no orthogonalization procedure. 
%       If mode=1 it is performed an orthonormalization on the matrix A.

comparison = [g g_est];

error = norm(g-g_est)^2/norm(g)^2

%email: araujo@gtel.ufc.br / daniel.c.araujo@gmail.com
