clear all;clc;close all;

% ------- Definitions -------
u = 129;
Nzc = 839;
NIFFT = 2048;
NIDFT = 24576;
v = [0];
Ncs = 13;
signal = complex(0,0)*zeros(1,NIFFT);
xuv = complex(0,0)*zeros(1,Nzc);

show_figures = false;

tx_shift_adjust = 10;

apply_time_domain_freq_shift = true;

%% *********************** PRACH Transmission *****************************

% ------------------- Generate local Zadoff-Chu sequence ------------------
n = [0:1:(Nzc-1)];
xu_root = exp(-1i*(pi*u.*n.*(n+1))./Nzc);
for i=1:1:length(v)
    Cv = v(i)*Ncs;
    xuv = xuv + xu_root(mod((n+Cv),Nzc)+1);
end

% ------- Generate base-band signal -------
Xuv = fft(xuv,Nzc);
signal(1:Nzc) = Xuv;
bb_signal = ifft(signal, NIFFT);

% ------- Add CP -------
% Preamble format 0:
Nseq = 2048;
Ncp = 264;
bb_signal_cp = [bb_signal(NIFFT-Ncp+1:NIFFT), bb_signal, zeros(1,tx_shift_adjust)];

if(show_figures)
    figure(1)
    stem(abs(fft(bb_signal_cp,NIFFT)));
    title('Base-band signal with CP - 2.56 Mbps');
end

% ------- Up-sampling by a factor of 12 -------
y = upsample(bb_signal_cp,12);

[Hd, h] = butterworth3; % Best response curve: flat!
%Hd = butterworth3_v2;
y_filtered = filter(Hd,y);

if(show_figures)
    figure(2)
    stem(10*log10(abs(fft(y,NIDFT))));
    title('Upsampled signal - 2.56 Mbps * 12 = 30.72 Mbps');
    
    figure(3)
    stem(10*log10(abs(fft(y_filtered((Ncp*12)+1:NIDFT+12*Ncp),NIDFT))));
    title('Low-pass filtered Upsampled signal');
end

y_filtered_adjusted = y_filtered(12*tx_shift_adjust+1:length(y_filtered));

% ------- Time-domain frequency shift -------
Ncp = 3168; % Ncp used after upsampling.
theta = 7;
K = 12;
Nrbsc = 12;
Nulrb = 25;
nraprb = 4;
ko = nraprb*Nrbsc - (Nulrb*Nrbsc)/2;
fo = theta+K*(ko+1/2);
m = 0:1:NIDFT+Ncp-1;
k = m-Ncp;
time_freq_shift = exp((1i*2*pi*fo*k)/NIDFT);
y_shifted = y_filtered_adjusted.*time_freq_shift;

% ------- Add Guard-band interval -------
NG = 2976;
tx_signal = [y_shifted, zeros(1,NG)];

if(show_figures)
    figure(4)
    stem(10*log10(abs(fft(tx_signal(Ncp+1:NIDFT+Ncp),NIDFT))));
    title('Time Domain Frequency Shifted Base-band Signal');
end

%% *************************** Rayleigh Channel ***************************
h = (randn() + 1i*randn());

y = h*xuv;

%% ************************* PRACH Reception ******************************

% ------- Remove CP and GB -------
rec_signal = tx_signal(Ncp+1:NIDFT+Ncp);

if(show_figures)
    figure(5)
    stem(10*log10(abs(fft(rec_signal,NIDFT))));
    title('Received base-band signal');
end

% ------- Time-domain frequency shift -------
m = 0:1:NIDFT-1;
time_freq_shift = exp((-1i*2*pi*fo*m)/NIDFT);
rec_signal_shifted = rec_signal.*time_freq_shift;

% Adjust delay added by the downsampling filter.
rx_shift_adjust = 3;%original: 3;
adjusted_rec_signal_shifted = [rec_signal_shifted zeros(1,12*rx_shift_adjust)];

if(show_figures)
    figure(6)
    stem(10*log10(abs(fft(adjusted_rec_signal_shifted,NIDFT))));
    title('Time-domain frequency shifted Received base-band signal');
end

% ------- Downsampling with polyphase filter -------
downsample_factor = 12;

use_butterworth = false;

if(rx_shift_adjust==0)
    downsampled_signal = downsample(adjusted_rec_signal_shifted,downsample_factor);
else
    if(use_butterworth)
        y_filtered = filter(Hd,adjusted_rec_signal_shifted);
        downsampled_signal = downsample(y_filtered,downsample_factor);
    else
        num = [0.00017939033531018 0.000373331595313973 0.00071274312540008 0.00121789473997835 0.00189381011836236 0.00275388375215944 0.00376067623652285 0.00487234517759502 0.00598957449393566 0.00700728758190838 0.00777151701050356 0.00814045427108632 0.00795185498237852 0.00709158862282701 0.00546778367396934 0.00307861305755767 -1.63753592195977e-005 -0.00363923795041085 -0.00753728454262852 -0.0113456884758382 -0.0146531315425441 -0.0169868383944301 -0.017897105615824 -0.0169574750468651 -0.0138553470030869 -0.00839044785522955 -0.000552643816493893 0.00950073408600361 0.0213970980368926 0.0346051144947382 0.0484238439582872 0.0620729050177951 0.0747101454691587 0.0855405957225286 0.0938411757641215 0.0990638802182588 0.100842037329038 0.0990638802182588 0.0938411757641215 0.0855405957225286 0.0747101454691587 0.0620729050177951 0.0484238439582872 0.0346051144947382 0.0213970980368926 0.00950073408600361 -0.000552643816493893 -0.00839044785522955 -0.0138553470030869 -0.0169574750468651 -0.017897105615824 -0.0169868383944301 -0.0146531315425441 -0.0113456884758382 -0.00753728454262852 -0.00363923795041085 -1.63753592195977e-005 0.00307861305755767 0.00546778367396934 0.00709158862282701 0.00795185498237852 0.00814045427108632 0.00777151701050356 0.00700728758190838 0.00598957449393566 0.00487234517759502 0.00376067623652285 0.00275388375215944 0.00189381011836236 0.00121789473997835 0.00071274312540008 0.000373331595313973 0.00017939033531018];
        %num = [0.000985883745225074 0.000571730044950101 0.000106648126098246 -0.000372859144745110 -0.000828674633492855 -0.00122408684737778 -0.00152673612473839 -0.00171125150124974 -0.00176136428524847 -0.00167132330363682 -0.00144649012413785 -0.00110305626222349 -0.000666893510920323 -0.000171617664595861 0.000343990449754349 0.000839009695914871 0.00127361411293862 0.00161226429772690 0.00182659995559342 0.00189779927541984 0.00181821007374360 0.00159211297012089 0.00123554402357492 0.000775178100388702 0.000246348982126550 -0.000309648063607325 -0.000848766442474533 -0.00132768269601734 -0.00170726236124098 -0.00195574118778643 -0.00205136443042600 -0.00198426639679932 -0.00175742975412938 -0.00138663498483221 -0.000899389394843187 -0.000332906064928914 0.000268720304063119 0.000857927704240361 0.00138742829942066 0.00181398418532760 0.00210191747275139 0.00222607137351675 0.00217397834922199 0.00194705071814546 0.00156068399831732 0.00104324798986785 0.000434028598496930 -0.000219732252011108 -0.000866477318039691 -0.00145437650674634 -0.00193545596890774 -0.00226948678480866 -0.00242732008948476 -0.00239339441835665 -0.00216720235959237 -0.00176358277516862 -0.00121179591414801 -0.000553434670055185 0.000160681486310602 0.000874400163561107 0.00153062118307956 0.00207583305456908 0.00246444284777542 0.00266255175982144 0.00265086664134822 0.00242650089352537 0.00200350191784805 0.00141204042259248 0.000696301855833456 -8.87761313260143e-05 -0.000881682198113467 -0.00161911086683124 -0.00224097476119401 -0.00269525592635899 -0.00294230804415383 -0.00295825757089606 -0.00273721654072831 -0.00229210841353760 -0.00165401435553005 -0.000870062687236986 3.47296006452683e-18 0.000888310488950731 0.00172412800415328 0.00243941030079198 0.00297429162010373 0.00328202624271475 0.00333299464820063 0.00311743502262892 0.00264665652628184 0.00195260554048803 0.00108578346199255 0.000111644756652443 -0.000894273243077470 -0.00185213170423268 -0.00268404593722136 -0.00332033126237490 -0.00370524489687283 -0.00380175813062675 -0.00359495876015873 -0.00309378235335580 -0.00233089543725211 -0.00136069497412330 -0.000255535849895172 0.000899559834457549 0.00201333232141247 0.00299537439633412 0.00376334018945476 0.00424970754956242 0.00440754956874589 0.00421483449561003 0.00367687607375226 0.00282669125103527 0.00172317953805641 0.000447206399247427 -0.000904160828554013 -0.00222486479983389 -0.00340799392537514 -0.00435423127720299 -0.00497996399285805 -0.00522440808221472 -0.00505516124465555 -0.00447170107705654 -0.00350649111425591 -0.00222353245457569 -0.000714391670320336 0.000908068004136106 0.00251784050056675 0.00398524536212579 0.00518702058482605 0.00601627893407062 0.00639155204324081 0.00626419052327356 0.00562348933963763 0.00449905991293265 0.00296016382719869 0.00111194437221733 -0.000911274372296128 -0.00295522270482528 -0.00485685023462737 -0.00645664808902501 -0.00761123986110464 -0.00820529889389262 -0.00816186371928110 -0.00745020685558188 -0.00609056074187580 -0.00415520949347173 -0.00176570318679988 0.000913774192625844 0.00368657026952340 0.00633668148794786 0.00864400390980380 0.0104007137056893 0.0114276529636390 0.0115895517946727 0.0108079542783633 0.00907083331741980 0.00643807197226884 0.00304224490479504 -0.000915562986510245 -0.00517483266943229 -0.00942917745941888 -0.0133436770252777 -0.0165749777192713 -0.0187929398743811 -0.0197024710297928 -0.0190641301783959 -0.0167121276004724 -0.0125684768896479 -0.00665227329354052 0.000916637547503753 0.00991999212243567 0.0200494580232797 0.0309206304450712 0.0420919409069932 0.0530874187356353 0.0634219858369067 0.0726277872373929 0.0802799762999326 0.0860203907003012 0.0895776728037567 0.0907825989273469 0.0895776728037567 0.0860203907003012 0.0802799762999326 0.0726277872373929 0.0634219858369067 0.0530874187356353 0.0420919409069932 0.0309206304450712 0.0200494580232797 0.00991999212243567 0.000916637547503753 -0.00665227329354052 -0.0125684768896479 -0.0167121276004724 -0.0190641301783959 -0.0197024710297928 -0.0187929398743811 -0.0165749777192713 -0.0133436770252777 -0.00942917745941888 -0.00517483266943229 -0.000915562986510245 0.00304224490479504 0.00643807197226884 0.00907083331741980 0.0108079542783633 0.0115895517946727 0.0114276529636390 0.0104007137056893 0.00864400390980380 0.00633668148794786 0.00368657026952340 0.000913774192625844 -0.00176570318679988 -0.00415520949347173 -0.00609056074187580 -0.00745020685558188 -0.00816186371928110 -0.00820529889389262 -0.00761123986110464 -0.00645664808902501 -0.00485685023462737 -0.00295522270482528 -0.000911274372296128 0.00111194437221733 0.00296016382719869 0.00449905991293265 0.00562348933963763 0.00626419052327356 0.00639155204324081 0.00601627893407062 0.00518702058482605 0.00398524536212579 0.00251784050056675 0.000908068004136106 -0.000714391670320336 -0.00222353245457569 -0.00350649111425591 -0.00447170107705654 -0.00505516124465555 -0.00522440808221472 -0.00497996399285805 -0.00435423127720299 -0.00340799392537514 -0.00222486479983389 -0.000904160828554013 0.000447206399247427 0.00172317953805641 0.00282669125103527 0.00367687607375226 0.00421483449561003 0.00440754956874589 0.00424970754956242 0.00376334018945476 0.00299537439633412 0.00201333232141247 0.000899559834457549 -0.000255535849895172 -0.00136069497412330 -0.00233089543725211 -0.00309378235335580 -0.00359495876015873 -0.00380175813062675 -0.00370524489687283 -0.00332033126237490 -0.00268404593722136 -0.00185213170423268 -0.000894273243077470 0.000111644756652443 0.00108578346199255 0.00195260554048803 0.00264665652628184 0.00311743502262892 0.00333299464820063 0.00328202624271475 0.00297429162010373 0.00243941030079198 0.00172412800415328 0.000888310488950731 3.47296006452683e-18 -0.000870062687236986 -0.00165401435553005 -0.00229210841353760 -0.00273721654072831 -0.00295825757089606 -0.00294230804415383 -0.00269525592635899 -0.00224097476119401 -0.00161911086683124 -0.000881682198113467 -8.87761313260143e-05 0.000696301855833456 0.00141204042259248 0.00200350191784805 0.00242650089352537 0.00265086664134822 0.00266255175982144 0.00246444284777542 0.00207583305456908 0.00153062118307956 0.000874400163561107 0.000160681486310602 -0.000553434670055185 -0.00121179591414801 -0.00176358277516862 -0.00216720235959237 -0.00239339441835665 -0.00242732008948476 -0.00226948678480866 -0.00193545596890774 -0.00145437650674634 -0.000866477318039691 -0.000219732252011108 0.000434028598496930 0.00104324798986785 0.00156068399831732 0.00194705071814546 0.00217397834922199 0.00222607137351675 0.00210191747275139 0.00181398418532760 0.00138742829942066 0.000857927704240361 0.000268720304063119 -0.000332906064928914 -0.000899389394843187 -0.00138663498483221 -0.00175742975412938 -0.00198426639679932 -0.00205136443042600 -0.00195574118778643 -0.00170726236124098 -0.00132768269601734 -0.000848766442474533 -0.000309648063607325 0.000246348982126550 0.000775178100388702 0.00123554402357492 0.00159211297012089 0.00181821007374360 0.00189779927541984 0.00182659995559342 0.00161226429772690 0.00127361411293862 0.000839009695914871 0.000343990449754349 -0.000171617664595861 -0.000666893510920323 -0.00110305626222349 -0.00144649012413785 -0.00167132330363682 -0.00176136428524847 -0.00171125150124974 -0.00152673612473839 -0.00122408684737778 -0.000828674633492855 -0.000372859144745110 0.000106648126098246 0.000571730044950101 0.000985883745225074];
        hm = mfilt.firdecim(downsample_factor,num);
        downsampled_signal = filter(hm,adjusted_rec_signal_shifted);
    end
end

adjusted_downsampled_signal = downsampled_signal(rx_shift_adjust+1:length(downsampled_signal));

if(show_figures)
    figure(8)
    stem(10*log10(abs(fft(adjusted_downsampled_signal,NIFFT))));
    title('Downsampled received signal');
end

% ------- FFT received signal -------
rec_fft = fft(adjusted_downsampled_signal,NIFFT);

% ------- Sub-carrier de-mapping -------
rec_Xuv = rec_fft(1:Nzc);

% ------- Generate local Zadoff-Chu root sequence with fixing cyclic shift due to the delay caused by the filter(s) -------
Xu_root = fft(xu_root, Nzc);

% ------- Multiply Local Zadoff-Chu root sequence by received sequence -------
conj_Xu_root = conj(Xu_root);
multiplied_sequences = (rec_Xuv.*conj_Xu_root);

% ------- Squared modulus used for peak detection -------
pdp_freq = ifft(multiplied_sequences,Nzc)/Nzc;
pdp = abs(pdp_freq).^2;

figure;
stem(0:1:Nzc-1,pdp)






















% %r = cconv(y,conj(xu_root),Nzc)/Nzc; % FUNCIONA!!!!
% 
% Xuv = fft(y,Nzc);       % FUNCIONA!!!!
% Xu = fft(xu_root,Nzc);
% mult = Xuv .* conj(Xu);
% r = ifft(mult,Nzc)/Nzc;
% 
% pdp = abs(r).^2;
% 
% figure;
% stem(pdp)