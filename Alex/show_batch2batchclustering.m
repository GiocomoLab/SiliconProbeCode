mf = dir('F:\CatGT\catgt_AA_210114_1_210204_mismatch_1_g0\AA_210114_1_210204_mismatch_1_g0_imec0\imec0_ks2\rez.mat')
figure
for iF=1:numel(mf)
    rez = load(fullfile(mf(iF).folder,mf(iF).name));
    rez = rez.rez;
    subplot(1,2,1)
    imagesc(rez.ccb,[-5 5])
    title('batch 2 batch distance')
    axis image
    subplot(1,2,2)
    imagesc(rez.ccbsort,[-5 5])
    title('after sorting')
    axis image
    pause
    saveas(gcf,fullfile(mf(iF).folder,'batch_distance.png'))
    clf
    
end
    