clear all

%% csireader.m
%
% read and plot CSI from UDPs created using the nexmon CSI extractor (nexmon.org/csi)
% modify the configuration section to your needs
% make sure you run >mex unpack_float.c before reading values from bcm4358 or bcm4366c0 for the first time
%
% the example.pcap file contains 4(core 0-1, nss 0-1) packets captured on a bcm4358
%

%% configuration
CHIP = '4366c0';          % wifi chip (possible values 4339, 4358, 43455c0, 4366c0)
BW = 80;                % bandwidth
FILE = './dataset9w.pcap';% capture file 
NPKTS_MAX = 5000;       % max number of UDPs to process

%% read file
HOFFSET = 16;           % header offset
NFFT = BW*3.2;          % fft size
p = readpcap();
p.open(FILE);
n = min(length(p.all()),NPKTS_MAX);
p.from_start();
csi_buff = complex(zeros(n,NFFT),0);
k = 1;
while (k <= n)
    f = p.next();
    if isempty(f)
        disp('no more frames');
        break;
    end
    if f.header.orig_len-(HOFFSET-1)*4 ~= NFFT*4
        disp('skipped frame with incorrect size');
        continue;
    end
    payload = f.payload;
    H = payload(HOFFSET:HOFFSET+NFFT-1);
    if (strcmp(CHIP,'4339') || strcmp(CHIP,'43455c0'))
        Hout = typecast(H, 'int16');
    elseif (strcmp(CHIP,'4358'))
        Hout = unpack_float(int32(0), int32(NFFT), H);
    elseif (strcmp(CHIP,'4366c0'))
        Hout = unpack_float(int32(1), int32(NFFT), H);
    else
        disp('invalid CHIP');
        break;
    end
    Hout = reshape(Hout,2,[]).';
    cmplx = double(Hout(1:NFFT,1))+1j*double(Hout(1:NFFT,2));
    csi_buff(k,:) = cmplx.';
    k = k + 1;
end

%% testing and visualizing CSI

%% Amplitudes only

%ddata = convert2Aug(csi_buff);
wdata = convert2Aug(csi_buff);

%% Create labels

%dlabels = zeros(5000,1); % DRY
wlabels = ones(5000,1);  % WET

%% Save dry dataset

save 'dataset_d.mat' ddata dlabels

%% Save wet dataset

save 'dataset_w.mat' wdata wlabels

%% Check dataset

%clear all

% LOAD DATASETS IN CLC

%% merge and split dataset to train and test data
% train

A = ddata(1:4000,:);
A_labels = dlabels(1:4000,:);
B= wdata (1:4000,:);
B_labels = wlabels(1:4000,:);

% test
C = ddata(4001:5000,:);
C_labels = dlabels(4001:5000,:);
D = wdata (4001:5000,:);
D_labels = wlabels(4001:5000,:);

%% concat

train_data = cat(1,A,B)
train_labels = cat(1,A_labels,B_labels)
test_data = cat(1,C,D)
test_labels = cat(1,C_labels,D_labels)
%% save datasets

save 'dataset9.mat' train_data train_labels
save 'test_dataset9.mat' test_data test_labels

 %% plot
plotcsi(csi_buff, NFFT, false)





