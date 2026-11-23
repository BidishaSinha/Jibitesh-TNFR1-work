function classStats = plotClasswiseStatistics(T, outputFolder)

if nargin < 2
    outputFolder = 'Curvature_Classwise_Output';
end

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

pdfFile = fullfile(outputFolder,'Classwise_Statistics_AllFigures.pdf');

if exist(pdfFile,'file')
    delete(pdfFile);
end




T.Classification = categorical(T.Classification);
classes = categories(T.Classification);

% params = {'MeanCurvature','GaussianCurvature','Curvedness', ...
%           'SignedCurvedness','ShapeIndex','k1','k2', ...
%           'MeanIntensity','TotalIntensity','MaxIntensity','Area', ...
%           'Mean_FBR_SD','Mean_FBR_SDt','Mean_FBR_Tension', ...
%           'Median_FBR_SD','Median_FBR_SDt','Median_FBR_Tension'};

params = {'MeanCurvature', ...
          'SignedCurvedness','ShapeIndex', ...
          'MeanIntensity','TotalIntensity','MaxIntensity','Area', ...
          'Median_FBR_SD','Median_FBR_SDt','Median_FBR_Tension'};


params = params(ismember(params, T.Properties.VariableNames));

rows = [];
r = 0;

for p = 1:numel(params)

    param = params{p};
    valsAll = double(T.(param));

    valid = ~isnan(valsAll) & isfinite(valsAll) & ~isundefined(T.Classification);

    vals = valsAll(valid);
    groups = T.Classification(valid);

    if numel(vals) < 3
        continue
    end

    %% boxplot with individual symbols

    fig = figure('Color','w','WindowState','maximized');

    boxplot(vals, groups, 'Symbol','');
    hold on

    gcats = categories(groups);

    for c = 1:numel(gcats)
        idx = groups == gcats{c};
        y = vals(idx);
        x = c + 0.20*(rand(size(y))-0.5);

        plot(x, y, 'ko', ...
            'MarkerSize',5, ...
            'MarkerFaceColor','none');
    end

    ylabel(strrep(param,'_',' '));
    xlabel('Curvature class');
    title(['Class-wise comparison: ' strrep(param,'_',' ')], ...
        'Interpreter','none');

    set(gca,'XTickLabelRotation',45);
    grid on
    box off

    try
        pKW = kruskalwallis(vals, groups, 'off');
    catch
        pKW = NaN;
    end

    yl = ylim;
    xl = xlim;

    text(xl(1)+0.03*range(xl), yl(2)-0.08*range(yl), ...
        sprintf('Kruskal-Wallis p = %.3g', pKW), ...
        'FontSize',12, ...
        'BackgroundColor','w', ...
        'EdgeColor','k');

    saveClassFig(fig, ['Boxplot_' param], outputFolder, pdfFile);

    %% distribution by class

    fig = figure('Color','w','WindowState','maximized');

    tiledlayout(ceil(numel(classes)/2), 2, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    for c = 1:numel(classes)

        nexttile

        idx = T.Classification == classes{c};
        y = T.(param);
        y = y(idx);
        y = y(~isnan(y) & isfinite(y));

        histogram(y, 20);
        title(classes{c}, 'Interpreter','none');
        xlabel(strrep(param,'_',' '));
        ylabel('Count');
        grid on
        box off
    end

    sgtitle(['Distribution by class: ' strrep(param,'_',' ')], ...
        'Interpreter','none');

    saveClassFig(fig, ['Distribution_' param], outputFolder, pdfFile);

    %% mean +/- SEM bar plot

    means = nan(numel(classes),1);
    sems  = nan(numel(classes),1);
    ns    = nan(numel(classes),1);

    for c = 1:numel(classes)

        idx = T.Classification == classes{c};
        y = double(T.(param));
        y = y(idx);
        y = y(~isnan(y) & isfinite(y));

        ns(c) = numel(y);
        means(c) = mean(y,'omitnan');
        sems(c) = std(y,'omitnan') / sqrt(numel(y));

        r = r + 1;
        rows(r).Parameter = string(param);
        rows(r).Class = string(classes{c});
        rows(r).N = ns(c);
        rows(r).Mean = means(c);
        rows(r).Median = median(y,'omitnan');
        rows(r).SD = std(y,'omitnan');
        rows(r).SEM = sems(c);
        rows(r).KruskalWallisP = pKW;
    end

    fig = figure('Color','w','WindowState','maximized');

    bar(means);
    hold on
    errorbar(1:numel(classes), means, sems, ...
        'k.', 'LineWidth', 1.5);

    set(gca,'XTick',1:numel(classes), ...
        'XTickLabel',classes, ...
        'XTickLabelRotation',45);

    ylabel(strrep(param,'_',' '));
    xlabel('Curvature class');
    title(['Mean ± SEM by class: ' strrep(param,'_',' ')], ...
        'Interpreter','none');

    grid on
    box off

    saveClassFig(fig, ['MeanSEM_' param], outputFolder, pdfFile);

end

classStats = struct2table(rows);
writetable(classStats, fullfile(outputFolder,'Classwise_Statistics_Table.csv'));

end


function saveClassFig(fig, figTitle, outputFolder, pdfFile)

safeTitle = matlab.lang.makeValidName(char(figTitle));

if isempty(safeTitle)
    safeTitle = 'ClasswiseFigure';
end

figFile = fullfile(outputFolder, [safeTitle '.fig']);
pngFile = fullfile(outputFolder, [safeTitle '.png']);

drawnow;

savefig(fig, char(figFile));
exportgraphics(fig, char(pngFile), 'Resolution',300);
exportgraphics(fig, char(pdfFile), 'Append',true);

close(fig);

end