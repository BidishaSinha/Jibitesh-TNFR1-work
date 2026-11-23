function corrOut = plotCurvatureCorrelations(T, folder, outputFolder)

if nargin < 3 || isempty(outputFolder)
    outputFolder = fullfile(folder, 'Curvature_Analysis_Output');
end

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

pdfFile = fullfile(outputFolder,'Correlation_All_Figures.pdf');

if exist(pdfFile,'file')
    delete(pdfFile);
end

%% Define variable groups

% curvVars = {'MeanCurvature','GaussianCurvature','Curvedness', ...
            % 'SignedCurvedness','ShapeIndex','k1','k2'};
curvVars = {'MeanCurvature', 'SignedCurvedness','ShapeIndex'};

% fbrVars = {'Mean_FBR_SD','Mean_FBR_SDt','Mean_FBR_Tension', ...
           % 'Median_FBR_SD','Median_FBR_SDt','Median_FBR_Tension'};
fbrVars = {'Median_FBR_SD','Median_FBR_SDt','Median_FBR_Tension'};

objVars = {'MeanIntensity','TotalIntensity','MaxIntensity','Area'};

%% 1. Curvature versus FBR parameters

[corrOut.curv_vs_fbr.R, corrOut.curv_vs_fbr.P] = ...
    correlationMatrix(T, curvVars, fbrVars);

plotCorrelationHeatmaps(corrOut.curv_vs_fbr.R, ...
                        corrOut.curv_vs_fbr.P, ...
                        curvVars, fbrVars, ...
                        'Curvature vs FBR-based parameters', ...
                        outputFolder);

plotScatterGrid(T, fbrVars, curvVars, ...
                'Curvature vs FBR-based parameters', ...
                outputFolder);

%% 2. FBR parameters versus object intensity/area

[corrOut.fbr_vs_object.R, corrOut.fbr_vs_object.P] = ...
    correlationMatrix(T, fbrVars, objVars);

plotCorrelationHeatmaps(corrOut.fbr_vs_object.R, ...
                        corrOut.fbr_vs_object.P, ...
                        fbrVars, objVars, ...
                        'FBR-based parameters vs object properties', ...
                        outputFolder);

plotScatterGrid(T, objVars, fbrVars, ...
                'FBR-based parameters vs object properties', ...
                outputFolder);

%% 3. Curvature versus object intensity/area

[corrOut.curv_vs_object.R, corrOut.curv_vs_object.P] = ...
    correlationMatrix(T, curvVars, objVars);

plotCorrelationHeatmaps(corrOut.curv_vs_object.R, ...
                        corrOut.curv_vs_object.P, ...
                        curvVars, objVars, ...
                        'Curvature vs object properties', ...
                        outputFolder);

plotScatterGrid(T, objVars, curvVars, ...
                'Curvature vs object properties', ...
                outputFolder);

%% Save matrices

writematrix(corrOut.curv_vs_fbr.R, fullfile(outputFolder,'R_curvature_vs_FBR.csv'));
writematrix(corrOut.curv_vs_fbr.P, fullfile(outputFolder,'P_curvature_vs_FBR.csv'));

writematrix(corrOut.fbr_vs_object.R, fullfile(outputFolder,'R_FBR_vs_object.csv'));
writematrix(corrOut.fbr_vs_object.P, fullfile(outputFolder,'P_FBR_vs_object.csv'));

writematrix(corrOut.curv_vs_object.R, fullfile(outputFolder,'R_curvature_vs_object.csv'));
writematrix(corrOut.curv_vs_object.P, fullfile(outputFolder,'P_curvature_vs_object.csv'));


%% 4. Class-wise correlations

classes = unique(T.Classification);
corrOut.classwise = struct();

for c = 1:numel(classes)

    className = string(classes(c));
    Tc = T(T.Classification == classes(c), :);

    if height(Tc) < 4
        continue
    end

    safeName = matlab.lang.makeValidName(className);

    %% Curvature vs FBR, class-wise
    [corrOut.classwise.(safeName).curv_vs_fbr.R, ...
     corrOut.classwise.(safeName).curv_vs_fbr.P] = ...
        correlationMatrix(Tc, curvVars, fbrVars);

    plotCorrelationHeatmaps( ...
        corrOut.classwise.(safeName).curv_vs_fbr.R, ...
        corrOut.classwise.(safeName).curv_vs_fbr.P, ...
        curvVars, fbrVars, ...
        "Class " + className + ": Curvature vs FBR", ...
        outputFolder);

    %% FBR vs object properties, class-wise
    [corrOut.classwise.(safeName).fbr_vs_object.R, ...
     corrOut.classwise.(safeName).fbr_vs_object.P] = ...
        correlationMatrix(Tc, fbrVars, objVars);

    plotCorrelationHeatmaps( ...
        corrOut.classwise.(safeName).fbr_vs_object.R, ...
        corrOut.classwise.(safeName).fbr_vs_object.P, ...
        fbrVars, objVars, ...
        "Class " + className + ": FBR vs object properties", ...
        outputFolder);

    %% Curvature vs object properties, class-wise
    [corrOut.classwise.(safeName).curv_vs_object.R, ...
     corrOut.classwise.(safeName).curv_vs_object.P] = ...
        correlationMatrix(Tc, curvVars, objVars);

    plotCorrelationHeatmaps( ...
        corrOut.classwise.(safeName).curv_vs_object.R, ...
        corrOut.classwise.(safeName).curv_vs_object.P, ...
        curvVars, objVars, ...
        "Class " + className + ": Curvature vs object properties", ...
        outputFolder);

end

end

%%
function [Rmat, Pmat] = correlationMatrix(T, rowVars, colVars)

Rmat = nan(numel(rowVars), numel(colVars));
Pmat = nan(numel(rowVars), numel(colVars));

for r = 1:numel(rowVars)

    y = double(T.(rowVars{r}));

    for c = 1:numel(colVars)

        x = double(T.(colVars{c}));

        valid = ~isnan(x) & ~isnan(y) & isfinite(x) & isfinite(y);

        x1 = x(valid);
        y1 = y(valid);

        if numel(x1) > 3 && numel(unique(x1)) > 1 && numel(unique(y1)) > 1

            % Pearson using corrcoef
            [R, P] = corrcoef(x1, y1);

            Rmat(r,c) = R(1,2);
            Pmat(r,c) = P(1,2);

        end
    end
end

end
%%
function plotCorrelationHeatmaps(Rmat, Pmat, rowVars, colVars, figTitle, outputFolder)

fig = figure('Color','w','Name',figTitle,'WindowState','maximized');

imagesc(Rmat);
axis image
caxis([-1 1])
colorbar

% blue-white-red colormap
n = 256;
blue = [linspace(0,1,n/2)', linspace(0,1,n/2)', ones(n/2,1)];
red  = [ones(n/2,1), linspace(1,0,n/2)', linspace(1,0,n/2)'];
colormap([blue; red]);

set(gca,'XTick',1:numel(colVars), ...
        'XTickLabel',strrep(colVars,'_',' '), ...
        'YTick',1:numel(rowVars), ...
        'YTickLabel',strrep(rowVars,'_',' '), ...
        'XTickLabelRotation',45, ...
        'FontSize',12);

title(figTitle,'Interpreter','none');

for r = 1:size(Rmat,1)
    for c = 1:size(Rmat,2)

        if isnan(Rmat(r,c))
            txt = 'NA';
        else
            if Pmat(r,c) < 0.001
                stars = '***';
            elseif Pmat(r,c) < 0.01
                stars = '**';
            elseif Pmat(r,c) < 0.05
                stars = '*';
            else
                stars = '';
            end

            txt = sprintf('%.2f%s', Rmat(r,c), stars);
        end

        text(c,r,txt, ...
            'HorizontalAlignment','center', ...
            'FontWeight','bold', ...
            'FontSize',11, ...
            'Color','k');
    end
end

xlabel('Predictor / object or FBR variable');
ylabel('Curvature / response variable');

pdfFile = fullfile(outputFolder,'Correlation_All_Figures.pdf');

saveCurrentFigureSafe(gcf, figTitle, outputFolder, pdfFile);

end


function plotScatterGrid(T, xVars, yVars, figTitle, outputFolder)

pdfFile = fullfile(outputFolder,'Correlation_All_Figures.pdf');

fig = figure('Color','w',...
             'Name',figTitle,...
             'Units','normalized',...
             'OuterPosition',[0 0 1 1]);

nX = numel(xVars);
nY = numel(yVars);

plotID = 0;

for yid = 1:nY

    for xid = 1:nX

        plotID = plotID + 1;

        x = double(T.(xVars{xid}));
        y = double(T.(yVars{yid}));

        valid = ~isnan(x) & ~isnan(y) & isfinite(x) & isfinite(y);

        x = x(valid);
        y = y(valid);

        subplot(nY,nX,plotID)

        scatter(x,y,12,'ko','filled');
        hold on
        grid on
        box off

        if numel(x) > 3 && numel(unique(x)) > 1 && numel(unique(y)) > 1

            [R,P] = corrcoef(x,y);
            rVal = R(1,2);
            pVal = P(1,2);

            pf = polyfit(x,y,1);
            xf = linspace(min(x),max(x),100);
            yf = polyval(pf,xf);
            plot(xf,yf,'r-','LineWidth',1);

            txt = sprintf('r=%.2f\np=%.2g\nn=%d', ...
                          rVal, pVal, numel(x));
        else
            txt = sprintf('n=%d',numel(x));
        end

        xlabel(strrep(xVars{xid},'_',' '));
        ylabel(strrep(yVars{yid},'_',' '));

        xl = xlim;
        yl = ylim;

        text(xl(1)+0.05*range(xl), ...
             yl(2)-0.15*range(yl), ...
             txt, ...
             'FontSize',7, ...
             'BackgroundColor','w', ...
             'Margin',2);
    end
end

sgtitle(figTitle,'Interpreter','none');
saveCurrentFigureSafe(gcf, figTitle, outputFolder, pdfFile);

end


%%
function saveCurrentFigureSafe(figHandle, figTitle, outputFolder, pdfFile)

% Convert all path inputs to character vectors
outputFolder = char(outputFolder);
pdfFile = char(pdfFile);

if ~exist(outputFolder,'dir')
    mkdir(outputFolder);
end

% Make a safe non-empty filename
figTitle = char(string(figTitle));
safeTitle = matlab.lang.makeValidName(figTitle);

if isempty(safeTitle)
    safeTitle = 'CorrelationFigure';
end

% Avoid very long filenames
if numel(safeTitle) > 120
    safeTitle = safeTitle(1:120);
end

figName = char(fullfile(outputFolder, [safeTitle '.fig']));
pngName = char(fullfile(outputFolder, [safeTitle '.png']));
pdfFile = char(pdfFile);

disp(figName)   % optional debug line; remove later

savefig(figHandle, figName);
exportgraphics(figHandle, pngName, 'Resolution', 300);
exportgraphics(figHandle, pdfFile, 'Append', true);

end

