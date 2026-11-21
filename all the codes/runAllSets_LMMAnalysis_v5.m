function LMMResults = runAllSets_LMMAnalysis_v5(masterTableFile,outputDir)
% Integrated LMM + plotting workflow
% Uses:
%   Outcome ~ Predictor + (1|SetID:CellID)
%
% Outputs:
%   LMM_Results_Full.csv
%   LMM_Results_Ranked.csv
%   LME_FittedEffects_3x3.png/.fig
%   LME_EffectSummary.png/.fig
%   PredictionStruct.mat

if nargin<2
    outputDir='LMM_Output';
end
if ~exist(outputDir,'dir'); mkdir(outputDir); end

[~,~,ext]=fileparts(masterTableFile);
if strcmpi(ext,'.mat')
    S=load(masterTableFile);
    fn=fieldnames(S);
    tbl=S.(fn{1});
else
    tbl=readtable(masterTableFile);
end

tbl.CellID=categorical(tbl.CellID);
tbl.SetID=categorical(tbl.SetID);

models={
'MeanIntensity','Tension';
'Area','Tension';
'TotalIntensity','Tension';
'MeanIntensity','SDt';
'Area','SDt';
'TotalIntensity','SDt';
'MeanIntensity','SDs';
'Area','SDs';
'TotalIntensity','SDs'};

results=table();
PredictionStruct=struct();

%% LME fitted effects panel
f1=figure('Position',[100 100 1400 1000]);

for k=1:size(models,1)

    response=models{k,1};
    predictor=models{k,2};

    good=~isnan(tbl.(response)) & ~isnan(tbl.(predictor));
    T=tbl(good,:);

    formula=sprintf('%s ~ %s + (1|SetID:CellID)',response,predictor);
    lme=fitlme(T,formula);

    coefTbl=lme.Coefficients;
    idx=strcmp(coefTbl.Name,predictor);
    ci=coefCI(lme);

    mc=lme.ModelCriterion;

    results=[results;
        table(string(response),string(predictor),string(formula),...
        coefTbl.Estimate(idx),coefTbl.SE(idx),coefTbl.tStat(idx),...
        coefTbl.DF(idx),coefTbl.pValue(idx),...
        ci(idx,1),ci(idx,2),...
        height(T),numel(unique(T.CellID)),numel(unique(T.SetID)),...
        mc.AIC,mc.BIC,lme.LogLikelihood,...
        'VariableNames',{'Response','Predictor','Formula',...
        'Beta','SE','tStat','DF','PValue',...
        'CI_Lower','CI_Upper',...
        'NPuncta','NCells','NSets',...
        'AIC','BIC','LogLikelihood'})];

    save(fullfile(outputDir,...
        sprintf('LME_%s_vs_%s.mat',response,predictor)),'lme');

    subplot(3,3,k)

    gscatter(T.(predictor),T.(response),T.SetID);
    hold on

    xgrid=linspace(min(T.(predictor)),max(T.(predictor)),100)';

    predTbl=table();
    predTbl.(predictor)=xgrid;
    predTbl.SetID=categorical(repmat(T.SetID(1),100,1));
    predTbl.CellID=categorical(repmat(T.CellID(1),100,1));

    try
        [yhat,yCI]=predict(lme,predTbl,'Conditional',false);
    catch
        [yhat,yCI]=predict(lme,predTbl);
    end

    fill([xgrid;flipud(xgrid)],...
         [yCI(:,1);flipud(yCI(:,2))],...
         [0.8 0.8 0.8],...
         'EdgeColor','none','FaceAlpha',0.4);

    plot(xgrid,yhat,'k-','LineWidth',2);

    title(sprintf('%s vs %s\nbeta=%.3g p=%.3g',...
        response,predictor,...
        coefTbl.Estimate(idx),...
        coefTbl.pValue(idx)));

    xlabel(predictor);
    ylabel(response);

    PredictionStruct.(response).(predictor).xgrid=xgrid;
    PredictionStruct.(response).(predictor).yhat=yhat;
    PredictionStruct.(response).(predictor).yCI=yCI;
end

sgtitle('LME Population-Level Fits');

saveas(f1,fullfile(outputDir,'LME_FittedEffects_3x3.png'));
savefig(f1,fullfile(outputDir,'LME_FittedEffects_3x3.fig'));

%% Effect summary
f2=figure('Position',[100 100 1000 500]);

y=1:height(results);
errorbar(results.Beta,y,...
    results.Beta-results.CI_Lower,...
    results.CI_Upper-results.Beta,...
    'horizontal','o');

yticks(y);
yticklabels(strcat(results.Response," ~ ",results.Predictor));
xline(0,'--');
xlabel('Beta');
title('LME Effect Summary');

saveas(f2,fullfile(outputDir,'LME_EffectSummary.png'));
savefig(f2,fullfile(outputDir,'LME_EffectSummary.fig'));

writetable(results,fullfile(outputDir,'LMM_Results_Full.csv'));
rankedResults=sortrows(results,'PValue');
writetable(rankedResults,fullfile(outputDir,'LMM_Results_Ranked.csv'));

save(fullfile(outputDir,'LMM_Results.mat'),'results','rankedResults');
save(fullfile(outputDir,'PredictionStruct.mat'),'PredictionStruct');

LMMResults=results;
end
