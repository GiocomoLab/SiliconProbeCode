close all; clear all;
%pause(5000)
addpath(genpath('C:\code\KiloSort2')) % path to kilosort folder
addpath('C:\code\npy-matlab')
addpath(genpath('C:\code\AlexA_Library'))
addpath('C:\code\SiliconProbeCode\')

sessions = {...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\AppleBottom\20220309_AppleBottom_DY01_g0\20220309_AppleBottom_DY01_g0_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\AppleBottom\20220309_AppleBottom_DY01_g1\20220309_AppleBottom_DY01_g1_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\AppleBottom\20220309_AppleBottom_DY01_g2\20220309_AppleBottom_DY01_g2_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\AppleBottom\20220309_AppleBottom_DY01_g3\20220309_AppleBottom_DY01_g3_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\BaggySweatpants\20220309_BaggySweatpants_DY01_g0\20220309_BaggySweatpants_DY01_g0_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\BaggySweatpants\20220309_BaggySweatpants_DY01_g1\20220309_BaggySweatpants_DY01_g1_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\BaggySweatpants\20220309_BaggySweatpants_DY01_g2\20220309_BaggySweatpants_DY01_g2_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\BaggySweatpants\20220309_BaggySweatpants_DY01_g3\20220309_BaggySweatpants_DY01_g3_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\StrappyReeboks\20220309_StrappyReeboks_DY01_g0\20220309_StrappyReeboks_DY01_g0_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\StrappyReeboks\20220309_StrappyReeboks_DY01_g1\20220309_StrappyReeboks_DY01_g1_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\StrappyReeboks\20220309_StrappyReeboks_DY01_g2\20220309_StrappyReeboks_DY01_g2_imec0',...
    'Z:\giocomo\emijones\WT Sequences\2022_winter\Raw Data\Neural_Traces\StrappyReeboks\20220309_StrappyReeboks_DY01_g3\20220309_StrappyReeboks_DY01_g3_imec0'...
    };
    

for n = 1:numel(sessions)
    
    try
        reset(gpuDevice)
        run_ks2(sessions{n})
        close all
    catch e
        warning(e.message);
        warning('FAILED: %s\n', sessions{n});
        fprintf('Failed at datetime: %s\n', datestr(now,'yyyy-mm-dd HH:MM'))
    end
    
end
