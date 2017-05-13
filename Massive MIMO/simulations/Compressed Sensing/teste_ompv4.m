clear all;close all;clc;

N = 2048;                % number of OFDM subcarriers.
F = fft(eye(N));        % Fourier Basis.

%% Comment: The vector P addresses pilot sequences.
% Pilot sequence 
M = 16;                                         % Number of pilots. Length of the training sequence.
ppos = 1:N/M:N;                                 % Position of the pilot in the frequency domain.
fo = 1000; % in Hz.                             % Pilot frequency.
%P = exp(1i*2*pi*fo*(0:1:M-1)/M);                % Normalized pilot signal, i.e., unit power.

P = 1/sqrt(2)*(randn(1,M) + 1i*randn(1,M));

Pdiag = diag(P);

Fl = F(ppos,:);

%% ********* Channel ************
h0 = 0.5 + 1i*0.8;
h1 = 0.7 - 1i*0.3;
h2 = 0.1 - 1i*0.4;

energy = (abs(h0).^2 + abs(h1).^2 + abs(h2).^2) / 3;
normalization_factor = 1/sqrt(energy);

h0 = h0*normalization_factor;
h1 = h1*normalization_factor;
h2 = h2*normalization_factor;

g = zeros(N,1);
pos = [1 24 31];
L = pos(length(pos));
g(pos) = [h0 h1 h2];

channel_energy = sum(abs(g).^2)/3;

K = length(pos);                                % Number of non-zero entries

% Comments: The channel "h" has a structured model. You can insert more realistics channel models.
H = Fl*g; % h is the FFT of the channel g.

%% ************* Transmission ****************

% Transmitted signal in frequency domain.
s = Pdiag*H;

% noise
%rng(839);

SNR = 10; % SNR given in dB.
linearSNR = 10^(-SNR/20);
noise = linearSNR*((randn(size(s)) + 1i*randn(size(s))) / sqrt(2));

% received signal
x = s + noise;

% %% @@@@@@@@@@@@@@@ teste @@@@@@@@@@@@@@@@@@
% A = Pdiag*Fl(:,1:pos(length(pos)));
% [g_hat_cse_cosamp] = CoSaMP(A,x,K);
% 
% error_cse_cosamp = norm(g(1:length(g_hat_cse_cosamp))-g_hat_cse_cosamp)^2/norm(g(1:length(g_hat_cse_cosamp)))^2

%% ************ Compressed Sensing Estimation (CSE) ************

% Estimation of g
%A = Pdiag*Fl(:,1:pos(length(pos)));
A = Pdiag*Fl;
[g_hat_cse] = OMP_orig(A,x,K);

% Comments: The performance of OMP depends on the choice of F and P. In
% this example, I assume that the channel has Fourier structure. In more
% realistic channel problem, Fourier basis presents a power leakage which
% increases the number of non-zero entries of g. Therefore, the choice of
% the F impacts directly on the algorithm performance.

error_cse = norm(g(1:length(g_hat_cse))-g_hat_cse)^2/norm(g(1:length(g_hat_cse)))^2

%% ************* Least Squares Estimation (LSE) ******************

A = Pdiag*Fl(:,1:pos(length(pos)));

invMat = (((A'*A)^(-1))*A');

g_hat_lse = invMat*x;

error_lse = norm(g(1:length(g_hat_lse))-g_hat_lse)^2/norm(g(1:length(g_hat_lse)))^2

%% ************* Mean Squared Error Estimation (MMSE-E) ******************
invMat = (A'*A + ((linearSNR^2)/1)*eye(L))^-1;
invMat = invMat*A';

g_hat_mmsee = invMat*x;

error_mmsee = norm(g(1:length(g_hat_mmsee))-g_hat_mmsee)^2/norm(g(1:length(g_hat_mmsee)))^2