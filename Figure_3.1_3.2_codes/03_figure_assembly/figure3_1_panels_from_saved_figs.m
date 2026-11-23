src = '/Volumes/T7 Touch/Forcurvature/with_good_cells/set7/Plate8/Exported/Curvature_Analysis_Output_20260807_094538/MATLAB_SessionAnalysis_20260812_130033';
dst = fullfile(fileparts(mfilename('fullpath')),'panels_fig3_1');   % output: one PDF per panel
if ~exist(dst,'dir'), mkdir(dst); end
names = {'B1_classpct_snapshot','B2_curvature_by_class_snapshot','C1_SDcurvature_cluster_vs_random','C3_classmix_cluster_vs_random','A7_SDt_vs_NFlips','A9_correlation_heatmap_small'};
sizes = [255 185; 235 175; 185 165; 235 165; 205 165; 245 215];   % panel size, pt (w h)
FS = 7;
cls2 = {'CUP/\newlinePIT','TROUGH','SADDLE','RIDGE','DOME/\newlineHILL'};   % TeX line breaks (a raw newline splits into separate tick labels)   % two-line labels so neighbours never touch
for k = 1:numel(names)
    f = openfig(fullfile(src,[names{k} '.fig']),'invisible');
    f.Units = 'points'; f.Position = [50 50 sizes(k,:)];
    ax = findall(f,'Type','axes');
    set(findall(f,'-property','FontSize'),'FontSize',FS);
    for a = ax', try, a.XAxis.TickLabelRotation = 0; catch, end, end
    txt = findall(f,'Type','text');
    switch names{k}
        case 'B1_classpct_snapshot'
            a = ax(1); yt = a.YTick; a.YLim = [0 60]; a.YTick = yt(yt<=50);
            eb = findall(a,'Type','errorbar'); top = containers.Map('KeyType','double','ValueType','double');
            for e = eb', for i = 1:numel(e.XData)
                v = e.YData(i) + e.YPositiveDelta(i); key = round(e.XData(i));
                if ~isKey(top,key) || v > top(key), top(key) = v; end, end, end
            pooled = {}; px = [];
            for q = txt'
                s = strjoin(string(q.String),' ');
                if startsWith(s,'pooled'), pooled{end+1} = strrep(s,'pooled ',''); px(end+1) = q.Position(1); delete(q); %#ok<AGROW>
                elseif ~isempty(regexp(s,'^\d+\.\d%$','once'))       % percentage labels: sit above the taller error bar
                    key = round(q.Position(1)); q.VerticalAlignment = 'bottom';
                    if isKey(top,key), q.Position(2) = top(key) + 0.8; end
                end
            end
            [~,o] = sort(px); pooled = pooled(o);
            lab = {'CUP/','PIT';'TROUGH','';'SADDLE','';'RIDGE','';'DOME/','HILL'};
            tl = cell(1,5);
            for i = 1:5
                s = lab{i,1}; if ~isempty(lab{i,2}), s = [s '\newline' lab{i,2}]; end
                if i <= numel(pooled), s = sprintf('%s\\newline\\fontsize{5.5}\\color[rgb]{.45 .45 .45}pooled\\newline%s', s, pooled{i}); end
                tl{i} = s;
            end
            a.TickLabelInterpreter = 'tex'; a.XTickLabel = tl;
            a.XAxis.FontSize = 6.5;
        case 'B2_curvature_by_class_snapshot'
            a = ax(1); title(a,'Mean curvature by class','FontSize',FS+0.5);
            a.TickLabelInterpreter = 'tex'; a.XTickLabel = cls2;
        case 'C1_SDcurvature_cluster_vs_random'
            a = ax(1); title(a,'');                                    % y-range left as saved
            for q = txt'
                s = strjoin(string(q.String),' ');
                if startsWith(s,'Mann-Whitney'), xlabel(a, s, 'FontSize',FS,'FontWeight','normal'); delete(q); end
            end
        case 'C3_classmix_cluster_vs_random'
            a = ax(1); title(a,''); a.YLim = [0 68]; a.YTick = 0:10:50; a.TickLabelInterpreter = 'tex'; a.XTickLabel = cls2;
            lg = findall(f,'Type','legend'); for l = lg', l.Location = 'northwest'; l.FontSize = FS; end   % legend shifted left, clear of the SADDLE bar/labels
        case 'A7_SDt_vs_NFlips'
            a = ax(1); title(a,''); a.YLabel.String = {'Number of curvature sign flips','(2048 frames)'};
        case 'A9_correlation_heatmap_small'
            title(ax(1),'');
            for a = ax', try, a.XAxis.TickLabelRotation = 90; catch, end, end
            hh = findall(f,'-property','String');
            for q = hh'
                try
                    s = strjoin(string(q.String),' ');
                    if contains(s,'p<0.05'), delete(q);
                    else
                        tk = regexp(s,'^(-?\d\.\d\d)(\**)$','tokens','once');
                        if ~isempty(tk)
                            q.FontSize = 5.5;
                            if ~isempty(tk{2}), q.String = {tk{1}; tk{2}}; end    % value over stars: fits inside the cell
                        end
                    end
                catch, end
            end
    end
    f.PaperUnits = 'points'; f.PaperSize = sizes(k,:); f.PaperPositionMode = 'auto';
    print(f, fullfile(dst,[names{k} '.pdf']), '-dpdf', '-painters');
    close(f); fprintf('done %s\n', names{k});
end
disp('ALL DONE');
