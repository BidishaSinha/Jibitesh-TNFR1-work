% Figure 3.2 panels (a-k): re-export the saved .fig files at a readable size (7 pt text), no panel titles (as in the thesis),
% stats lines moved below the axes so they cannot sit on data.
C = '/Volumes/T7 Touch/Forcurvature/with_good_cells/set7/Plate8/MATLAB_Control_vs_TNFa_20260813_002339/';
N = '/Volumes/T7 Touch/Forcurvature/For TNFa/set2/Plate5/Exported/Curvature_Analysis_Output_20260812_203348/MATLAB_New_vs_PreExisting_20260813_200546/';
dst = [fullfile(fileparts(mfilename('fullpath')),'panels_fig3_2') filesep];   % output: one PDF per panel
if ~exist(dst,'dir'), mkdir(dst); end
P = {  % letter, fig path, w, h (pt), kind
 'a',[C 'N1_classmix_control_vs_tnfa.fig'],              240,175,'class';
 'b',[C 'N3_SDt_control_vs_tnfa.fig'],                   170,165,'box';
 'c',[C 'N4_Tension_control_vs_tnfa.fig'],               170,165,'box';
 'd',[C 'N5_SDcurvature_control_vs_tnfa.fig'],           180,165,'box';
 'e',[C 'N8_SDt_vs_SDcurvature_control_vs_tnfa.fig'],    215,200,'scatter';
 'f',[C 'N9_SDt_vs_FracClassChanges_control_vs_tnfa.fig'],215,200,'scatter';
 'g',[N 'Q1_Area_new_vs_preexisting.fig'],               170,165,'box';
 'h',[N 'Q2_Circularity_new_vs_preexisting.fig'],        170,165,'box';
 'i',[N 'Q5_MeanIntensity_new_vs_preexisting.fig'],      170,165,'box';
 'j',[N 'Q11_classmix_new_vs_preexisting.fig'],          240,175,'class';
 'k',[N 'Q9_SDcurvature_new_vs_preexisting.fig'],        180,165,'box'};
FS = 7;
for k = 1:size(P,1)
    L = P{k,1}; f = openfig(P{k,2},'invisible');
    f.Units = 'points'; f.Position = [50 50 P{k,3} P{k,4}];
    ax = findall(f,'Type','axes'); a = ax(1);
    set(findall(f,'-property','FontSize'),'FontSize',FS);
    for q = ax', try, q.XAxis.TickLabelRotation = 0; catch, end, end
    title(a,'');
    txt = findall(f,'Type','text');
    fprintf('%s: ', L);
    switch P{k,5}
        case 'box'        % stats line goes under the axis (no collisions with outliers)
            if L == 'g'      % more room on the left: axes start further in, y label placed clear of the 3-digit tick numbers
                dx = 0.25 - a.Position(1); a.Position(1) = 0.25; a.Position(3) = a.Position(3) - dx;
                a.YLabel.Units = 'normalized'; a.YLabel.Position(1) = -0.22;
            end
            for q = txt'
                s = strjoin(string(q.String),' ');
                if startsWith(s,'Mann-Whitney'), xlabel(a, boldP(s), 'FontSize',FS,'FontWeight','normal'); delete(q); fprintf('stats->xlabel; '); end
            end
            yl = strjoin(string(a.YLabel.String),' ');
            if contains(yl,'(2048 frames)'), a.YLabel.String = {strtrim(erase(yl,'(2048 frames)')),'(2048 frames)'}; end
        case 'scatter'    % legend stays inside (top right, empty region); the small gray stats text becomes extra xlabel lines
            extra = '';
            for q = findall(f,'-property','String')'
                try, s = strjoin(string(q.String),' '); catch, continue, end
                if startsWith(s,'Mann-Whitney'), extra = s; fprintf('found stats object (%s); ', class(q)); delete(q); end
            end
            a.Position(2) = a.Position(2) + 0.13; a.Position(4) = a.Position(4) - 0.13;   % room for the 3-line x label
            xl = strjoin(string(a.XLabel.String),' ');
            if ~isempty(extra)
                parts = strsplit(strrep(extra,'TNFa','TNF\alpha'),'x-variable');   % "Mann-Whitney, Control vs. TNFa:" | " p=... y-variable p=..."
                xlabel(a, {xl, strtrim(parts{1}), boldP(['x-variable' regexprep(parts{2},'\s+',' ')])}, 'FontSize',FS-0.5,'FontWeight','normal');
                fprintf('stats->xlabel; ');
            end
            yl = strjoin(string(a.YLabel.String),' ');
            if contains(yl,'Fraction of frames with a class change'), a.YLabel.String = {'Fraction of frames with','a class change'}; end
        case 'class'
            a.TickLabelInterpreter = 'tex';
            a.XTickLabel = {'CUP/\newlinePIT','TROUGH','SADDLE','RIDGE','DOME/\newlineHILL'};
            if L == 'j'      % legend top-left over the short CUP/PIT + TROUGH bars; headroom so it clears the data
                a.YLim = [0 72]; a.YTick = 0:10:60;
                for l = findall(f,'Type','legend')', l.Location = 'northwest'; l.FontSize = FS; end
            end
    end
    if ismember(L,{'a','b','c','d','e','f'})      % condition name as in the thesis (TNF-alpha); p printed as p<1e-16 instead of p=0
        tl = a.XTickLabel;
        if any(strcmp(tl,'TNFa')), a.TickLabelInterpreter = 'tex'; a.XTickLabel = strrep(tl,'TNFa','TNF\alpha'); end
        for lg = findall(f,'Type','legend')'
            lg.Interpreter = 'tex'; ls = lg.String; ls = strrep(ls,'TNFa','TNF\alpha'); ls = strrep(ls,'p=0 (','p<1e-16 ('); lg.String = boldP(ls);
        end
    end
    f.PaperUnits = 'points'; f.PaperSize = [P{k,3} P{k,4}]; f.PaperPositionMode = 'auto';
    print(f, [dst L '.pdf'], '-dpdf', '-painters'); close(f); fprintf('done\n');
end
disp('ALL DONE');

function s = boldP(s)
% wrap every "p=..." / "p<..." (plus trailing significance stars) in TeX bold so it prints in bold
    s = regexprep(s, '(p[=<][0-9.e+\-]+(\s?\*+)?)', '{\\bf $1}');
end
