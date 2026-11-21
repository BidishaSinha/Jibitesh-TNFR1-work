clear;clc

flip_tr_path = "H:\Jibitesh\STED\210526\TNFa\after\1\Sample 2\Overview 35 - Image 1 - 17_55_33 - eGFP lifetime.ome.tiff";
mcherry_lt_path = "H:\Jibitesh\STED\210526\TNFa\after\1\Sample 2\Overview 35 - Image 1 - 17_55_33 - mCherry lifetime.ome.tiff";
mcherry_path = "H:\Jibitesh\STED\210526\TNFa\after\1\Sample 2\Overview 35 - Image 1 - 17_55_33 - mCherry.ome.tiff";
filptr_image = imread(flip_tr_path);
mcherry_image = imread(mcherry_path);
mcherry_lt_image  = imread(mcherry_lt_path);
lowerThreshold = 10;
upperThreshold = 1000;

redrawing = true;
while redrawing
    imshow(mcherry_image,[1e-10 20e-10]);  % Display the black and white image
    title('Draw the cell bounary');
    % Allow the user to select only the cell of importance
    mask_handle = drawfreehand('Color','r','LineWidth',2);

    % Option to redraw or exit
    choice = questdlg("Redraw mask?", "Freehand Mask", "Yes", "No", "Yes");

    % Update flag based on user choice
    redrawing = strcmp(choice, "Yes");

    % Clear the previous mask for redraw (if needed)
    if redrawing
        delete(mask_handle);
    end
end
% Create a binary mask from the freehand boundary
mask = mask_handle.createMask;
close;


continue_drawing = true;
while continue_drawing
    imshow(mcherry_image,[1e-10 20e-10]);  % Display the black and white image
    title('Draw the Background');
    h = drawrectangle('InteractionsAllowed', 'all', 'Color', 'r');

    % Extract top-left corner and dimensions
    top_left = h.Position(1:2);
    width = h.Position(3);
    height = h.Position(4);

    % Ensure the shape is a square
    side_length = min(width, height);
    square_coords = [top_left;
        top_left + [side_length, 0];
        top_left + [side_length, side_length];
        top_left + [0, side_length];
        top_left];  % Close the square


    % Confirm the ROI or redraw
    choice = questdlg('Do you want to keep this ROI or redraw?', ...
        'Confirm ROI', ...
        'Keep', 'Redraw', 'Keep');
    if strcmp(choice, 'Redraw')
        delete(h); % Remove the drawn rectangle
        delete(square_plot); % Remove the displayed red square
        continue;  % Restart the loop
    else
        continue_drawing=false;
    end
end
close;

max_row = round(square_coords(3, 2));
min_row = round(square_coords(2, 2));
max_col = round(square_coords(2, 1));
min_col = round(square_coords(1, 1));


bg_lt_fliptr = filptr_image(min_row:max_row, min_col:max_col);
bg_lt_mcherry = mcherry_lt_image(min_row:max_row, min_col:max_col);
fliptr_thresh = mean(bg_lt_fliptr(:));
mcherry_thresh = mean(bg_lt_mcherry(:));

binary_fliptr_img = filptr_image > fliptr_thresh;
binary_mcherry_lt_img = mcherry_lt_image > mcherry_thresh;
binary_fliptr_img(~mask) = 0;
binary_mcherry_lt_img(~mask) = 0;
idx_pix_mcherrry = find(binary_mcherry_lt_img>0);
idx_pix_fliptr = find(binary_fliptr_img>0);
fliptr_img_norm = zeros(size(filptr_image));
mcherry_img_norm = zeros(size(mcherry_image));
fliptr_img_norm(idx_pix_fliptr) = filptr_image(idx_pix_fliptr);
mcherry_img_norm(idx_pix_mcherrry) = mcherry_image(idx_pix_mcherrry);
mcherry_lt_img_norm(idx_pix_mcherrry) = mcherry_lt_image(idx_pix_mcherrry);
binary_mcherry_img = mcherry_img_norm>0;
%% ============================================================
% Whole Cell Local Analysis (5x5 ROIs)
%% ============================================================

roiSize_local = 5;

LocalData = [];
roiCount = 0;

figure;
imshow(mcherry_img_norm,[]);
hold on;
title('Whole Cell 5x5 ROIs');

for y = 1:roiSize_local:size(mask,1)-roiSize_local+1

    for x = 1:roiSize_local:size(mask,2)-roiSize_local+1

        roiMask = mask(y:y+roiSize_local-1,...
                       x:x+roiSize_local-1);

        % Keep ROIs completely inside cell
        if all(roiMask(:))

            roiLT = fliptr_img_norm(y:y+roiSize_local-1,...
                                    x:x+roiSize_local-1);

            roiMC = mcherry_img_norm(y:y+roiSize_local-1,...
                                     x:x+roiSize_local-1);

            lt = roiLT(:);
            mc = roiMC(:);

            valid = lt>0;

            lt = lt(valid);
            mc = mc(valid);

            if ~isempty(lt)

                roiCount = roiCount+1;

                LocalData(roiCount,:) = [...
                    x+2,...
                    y+2,...
                    mean(lt),...
                    std(lt),...
                    mean(mc),...
                    std(mc),...
                    sum(mc)];

                rectangle('Position',[x y 5 5],...
                    'EdgeColor','g',...
                    'LineWidth',0.25);

            end

        end

    end

end

hold off;

LocalTable = array2table(LocalData,...
'VariableNames',{'CenterX',...
'CenterY',...
'MeanLifetime',...
'StdLifetime',...
'MeanMCherry',...
'StdMCherry',...
'IntegratedMCherry'});

% Create a labeled image initialized with the original image
labeled_image = zeros(size(binary_fliptr_img));

% Get properties using a single regionprops call
stats_1 = regionprops(binary_fliptr_img,fliptr_img_norm, 'all');
stats_2 = regionprops(binary_mcherry_img,mcherry_img_norm, 'all');
%% Statistics for the TNFR1 mcherry clusters

% Initialize component indices and areas arrays
centroids = [];
peakCoordinates = [];

mean_cluster_lt = [];
mean_clust_fliptr_lt = [];
componentIndices = [];

% Loop through all connected components
for i = 1:length(stats_2)

    currentArea = stats_2(i).Area;

    if currentArea >= lowerThreshold && ...
       currentArea < upperThreshold

        % Pixels belonging to this segmented cluster
        object_pixels = stats_2(i).PixelIdxList;

        labeled_image(object_pixels) = i;

        % =====================================================
        % FIND HIGHEST INTENSITY mCherry PIXEL
        % =====================================================

        pixelIntensity = double(mcherry_img_norm(object_pixels));

        [~, maxIdx] = max(pixelIntensity);

        peakPixel = object_pixels(maxIdx);

        % Convert brightest pixel index to X,Y
        [peakY, peakX] = ...
            ind2sub(size(mcherry_img_norm), peakPixel);

        % Store brightest pixel coordinates
        peakCoordinates = [peakCoordinates; peakX peakY];

        % Keep centroid separately if you still want it
        centroids = [centroids; stats_2(i).Centroid];

        % Cluster mean values
        mean_cluster_lt = ...
            [mean_cluster_lt; stats_2(i).MeanIntensity];

        mean_clust_fliptr_lt = ...
            [mean_clust_fliptr_lt; ...
             mean(fliptr_img_norm(object_pixels))];

        componentIndices = ...
            [componentIndices; i];

    end
end
% Number of objects detected BEFORE manual selection
n_objects = size(peakCoordinates,1);

%% ============================================================
% MANUAL CLUSTER SELECTION
% Click clusters to KEEP, press ENTER when finished
%% ============================================================

RGB = zeros(size(binary_mcherry_img,1), ...
            size(binary_mcherry_img,2), 3);

% Blue background
RGB(:,:,3) = 0.8;

% Detected clusters shown in yellow
RGB(:,:,1) = binary_mcherry_img;
RGB(:,:,2) = binary_mcherry_img;

figure;
imshow(RGB);
hold on;

title({'Click clusters to KEEP'; ...
       'Selected clusters become RED'; ...
       'Press ENTER when finished'});

selectedClusters = [];

while true

    [xClick,yClick,button] = ginput(1);

    % ENTER pressed
    if isempty(button)
        break
    end

    xx = round(xClick);
    yy = round(yClick);

    % Ignore clicks outside image
    if xx < 1 || ...
       xx > size(labeled_image,2) || ...
       yy < 1 || ...
       yy > size(labeled_image,1)

        continue
    end

    % Find cluster label at clicked position
    clickedLabel = labeled_image(yy,xx);

    % Ignore background
    if clickedLabel == 0
        continue
    end

    % Find corresponding position in componentIndices
    idx = find(componentIndices == clickedLabel);

    if isempty(idx)
        continue
    end

    % ---------------------------------------------------------
    % Toggle selection
    % ---------------------------------------------------------

    if ismember(idx,selectedClusters)

        % Remove from selection
        selectedClusters(selectedClusters == idx) = [];

    else

        % Add to selection
        selectedClusters(end+1) = idx;

    end

    % ---------------------------------------------------------
    % Refresh display
    % ---------------------------------------------------------

    RGB = zeros(size(binary_mcherry_img,1), ...
                size(binary_mcherry_img,2), 3);

    % Blue background
    RGB(:,:,3) = 0.8;

    % Detected clusters = yellow
    RGB(:,:,1) = binary_mcherry_img;
    RGB(:,:,2) = binary_mcherry_img;

    % Selected clusters = red
    selectedMask = ismember( ...
        labeled_image, ...
        componentIndices(selectedClusters));

    RGB(:,:,1) = RGB(:,:,1) + selectedMask;
    RGB(:,:,2) = RGB(:,:,2) .* (~selectedMask);
    RGB(:,:,3) = RGB(:,:,3) .* (~selectedMask);

    imshow(RGB);
    hold on;

    title({['Selected clusters = ' ...
            num2str(length(selectedClusters))]; ...
           'Click to toggle selection'; ...
           'Press ENTER when finished'});

end

close;

%% ============================================================
% APPLY MANUAL SELECTION
%% ============================================================

selectedClusters = sort(selectedClusters);

% Keep only selected clusters
componentIndices = componentIndices(selectedClusters);

centroids = centroids(selectedClusters,:);

peakCoordinates = peakCoordinates(selectedClusters,:);

mean_cluster_lt = mean_cluster_lt(selectedClusters);

mean_clust_fliptr_lt = ...
    mean_clust_fliptr_lt(selectedClusters);

% Update number of objects
n_objects = length(componentIndices);

disp(['Manually selected clusters: ' ...
      num2str(n_objects)]);

%% ============================================================
% Extract ROIs ONLY from selected clusters
%% ============================================================

rois_mcherry = ...
    extractClusterROIs(mcherry_image,peakCoordinates);

rois_fliptr = ...
    extractClusterROIs(filptr_image,peakCoordinates);
figure;
imshow(binary_mcherry_img, []);
hold on;

% 2. Loop through centroids to draw rectangles
numClusters = size(peakCoordinates, 1);
roiSize = 10;
offset = roiSize / 2;

for i = 1:numClusters
    % Centroids are [x, y], rectangle function needs [x_min, y_min, width, height]
    % We subtract offset to center the 10x10 square on the centroid
    rect_pos = [peakCoordinates(i,1) - offset, ...
            peakCoordinates(i,2) - offset, ...
            roiSize, roiSize];
    
    % Draw the rectangle
    rectangle('Position', rect_pos, 'EdgeColor', 'yellow', 'LineWidth', 1.5);
end

title(['Detected Clusters (n = ' num2str(numClusters) ')']);
hold off;


% 2. Preallocate results
numClusters = size(rois_mcherry, 3);
mean_roi_mcherry = zeros(numClusters, 1);
mean_roi_fliptr = zeros(numClusters, 1);

% 3. Calculate means directly from the extracted ROIs
for k = 1:numClusters
    % Since rois_mcherry already contains the pixel intensities,
    % simply calculate the mean of that 10x10 slice.
    mean_roi_mcherry(k) = mean(rois_mcherry(:, :, k), 'all');
    mean_roi_fliptr(k) = mean(rois_fliptr(:, :, k), 'all'); 
end

[rows, cols] = ind2sub(size(mcherry_image), idx_pix_mcherrry);
line_scan_length = 50;
lt_scan_mcherry = zeros(n_objects,line_scan_length);
lt_scan_fliptr = zeros(n_objects,line_scan_length);
lt_scan_mcherry_x = zeros(n_objects,15);
lt_scan_fliptr_x = zeros(n_objects,15);
lt_scan_mcherry_y = zeros(n_objects,15);
lt_scan_fliptr_y = zeros(n_objects,15);
lt_scan_mcherry_xy = zeros(n_objects,15);
lt_scan_fliptr_xy = zeros(n_objects,15);

for k = 1:size(componentIndices,1)
    idx = componentIndices(k,1);
    % Example for the first detected object
    center = peakCoordinates(k,:);
    len = stats_2(idx).MajorAxisLength / 2;
    angle = -stats_2(idx).Orientation; % Negative because Y-axis is flipped in images

    % Calculate endpoints
    x_coords = [center(1) - len*cosd(angle), center(1) + len*cosd(angle)];
    y_coords = [center(2) - len*sind(angle), center(2) + len*sind(angle)];

    ls_mcherry = improfile(mcherry_image, x_coords, y_coords,line_scan_length,'nearest');
    ls_fliptr = improfile(filptr_image, x_coords, y_coords,line_scan_length,'nearest');

    lt_scan_mcherry(k,:) = ls_mcherry;
    lt_scan_fliptr(k,:) = ls_fliptr;

    half_len = 7;

    % X-Line Scan 
    x_coords_x = [center(1) - half_len, center(1) + half_len];
    y_coords_x = [center(2), center(2)];

    % Y-Line Scan 
    x_coords_y = [center(1), center(1)];
    y_coords_y = [center(2) - half_len, center(2) + half_len];
  
    ls_mcherry_x = improfile(mcherry_image, x_coords_x, y_coords_x, 15, 'bilinear');
    ls_mcherry_y = improfile(mcherry_image, x_coords_y, y_coords_y, 15, 'bilinear');

    ls_fliptr_x = improfile(filptr_image, x_coords_x, y_coords_x, 15, 'bilinear');
    ls_fliptr_y = improfile(filptr_image, x_coords_y, y_coords_y, 15, 'bilinear');
    
    lt_scan_mcherry_x(k,:) = ls_mcherry_x;
    lt_scan_fliptr_x(k,:) = ls_fliptr_x;

    lt_scan_mcherry_y(k,:) = ls_mcherry_y;
    lt_scan_fliptr_y(k,:) = ls_fliptr_y;

    lt_scan_fliptr_xy(k,:) = ls_fliptr_x + ls_fliptr_y;
    lt_scan_mcherry_xy(k,:)= ls_mcherry_x + ls_mcherry_y;
    
end

%%
x = 1:size(lt_scan_fliptr, 2); 
mean_line_fliptr = mean(lt_scan_fliptr, 1);
std_dev_fliptr = std(lt_scan_fliptr, 1);
mean_line_mcherry = mean(lt_scan_mcherry, 1);
std_dev_mcherry = std(lt_scan_mcherry, 1);
mean_line_mcherry_radial_avg = mean(lt_scan_mcherry_xy,1);
std_dev_mcherry_radial_avg = std(lt_scan_mcherry_xy,1);
mean_line_fliptr_radial_avg = mean(lt_scan_fliptr_xy,1);
std_dev_fliptr_radial_avg = std(lt_scan_fliptr_xy,1);

% Define boundaries
upper_bound_1 = mean_line_fliptr + (std_dev_fliptr/sqrt(n_objects));
lower_bound_1 = mean_line_fliptr - (std_dev_fliptr/sqrt(n_objects));

upper_bound_2 = mean_line_mcherry + (std_dev_mcherry/sqrt(n_objects));
lower_bound_2 = mean_line_mcherry - (std_dev_mcherry/sqrt(n_objects));

upper_bound_3 = mean_line_mcherry_radial_avg + (std_dev_mcherry_radial_avg/sqrt(n_objects));
lower_bound_3 = mean_line_mcherry_radial_avg - (std_dev_mcherry_radial_avg/sqrt(n_objects));

upper_bound_4 = mean_line_fliptr_radial_avg + (std_dev_fliptr_radial_avg/sqrt(n_objects));
lower_bound_4 = mean_line_fliptr_radial_avg - (std_dev_fliptr_radial_avg/sqrt(n_objects));


% Create figure with two y-axes
figure;
hold on;

% Left y-axis for fliptr (scale ~1e-9)
yyaxis left;
x2 = [x, fliplr(x)];
inBetween = [upper_bound_1, fliplr(lower_bound_1)];
h_shade_left = patch(x2, inBetween, 'blue', ...
    'FaceAlpha', 0.25, ...
    'EdgeColor', 'none');
h_mean_left = plot(x, mean_line_fliptr, 'Color', 'blue', 'LineWidth', 2);
ylabel('Signal Intensity (FLIPTR) - units');
ylim auto; % Automatically adjust based on data

% Right y-axis for mcherry (different scale)
yyaxis right;
x2 = [x, fliplr(x)];
inBetween = [upper_bound_2, fliplr(lower_bound_2)];
h_shade_right = patch(x2, inBetween, 'red', ...
    'FaceAlpha', 0.25, ...
    'EdgeColor', 'none');
h_mean_right = plot(x, mean_line_mcherry, 'Color', 'red', 'LineWidth', 2);
ylabel('Signal Intensity (MCHERRY) - units');
ylim auto;

% Labels and title
xlabel('Distance / Time');
title('Line Scan Population with Standard Deviation');
grid on;
box on;

hold off;

%%

% Helper function to create symmetric vector
makeSymmetric = @(v) [v, v(end-1:-1:1)];

% Apply to your means
sym_mean_mcherry = makeSymmetric(mean_line_mcherry_radial_avg(1:8));
sym_mean_fliptr = makeSymmetric(mean_line_fliptr_radial_avg(1:8));

% Apply to your bounds
sym_upper_mcherry = makeSymmetric(upper_bound_3(1:8));
sym_lower_mcherry = makeSymmetric(lower_bound_3(1:8));

sym_upper_fliptr = makeSymmetric(upper_bound_4(1:8));
sym_lower_fliptr = makeSymmetric(lower_bound_4(1:8));

% Define new symmetric X-axis
x_sym = 1:15; 

% 2. Plotting with symmetric data
figure;
hold on;

% Left Y-axis (FLIPTR)
yyaxis left;
patch([x_sym, fliplr(x_sym)], [sym_upper_fliptr, fliplr(sym_lower_fliptr)], ...
    'blue', 'FaceAlpha', 0.25, 'EdgeColor', 'none');
plot(x_sym, sym_mean_fliptr, 'Color', 'blue', 'LineWidth', 2);
ylabel('Signal Intensity (FLIPTR)');

% Right Y-axis (MCHERRY)
yyaxis right;
patch([x_sym, fliplr(x_sym)], [sym_upper_mcherry, fliplr(sym_lower_mcherry)], ...
    'red', 'FaceAlpha', 0.25, 'EdgeColor', 'none');
plot(x_sym, sym_mean_mcherry, 'Color', 'red', 'LineWidth', 2);
ylabel('Signal Intensity (MCHERRY)');

xlabel('Radial Distance (Pixels)');
title('Radially Symmetric Line Scan Profile');
grid on;


%% ============================================================
% Store Cluster Properties
%% ============================================================

clusterArea         = zeros(length(componentIndices),1);
clusterCircularity  = zeros(length(componentIndices),1);
clusterMajorAxis    = zeros(length(componentIndices),1);
clusterMinorAxis    = zeros(length(componentIndices),1);

for k = 1:length(componentIndices)

    idx = componentIndices(k);

    clusterArea(k)        = stats_2(idx).Area;
    clusterCircularity(k) = stats_2(idx).Circularity;
    clusterMajorAxis(k)   = stats_2(idx).MajorAxisLength;
    clusterMinorAxis(k)   = stats_2(idx).MinorAxisLength;

end

%% ============================================================
% Create Results Table
%% ============================================================

Results = table(...
    (1:length(componentIndices))', ...
    peakCoordinates(:,1), ...
    peakCoordinates(:,2), ...
    clusterArea, ...
    clusterCircularity, ...
    clusterMajorAxis, ...
    clusterMinorAxis, ...
    mean_roi_mcherry, ...
    mean_roi_fliptr, ...
    mean_cluster_lt, ...
    mean_clust_fliptr_lt, ...
    'VariableNames', { ...
    'ClusterID', ...
    'PeakX', ...
    'PeakY', ...
    'ClusterArea', ...
    'Circularity', ...
    'MajorAxis', ...
    'MinorAxis', ...
    'ROI_mCherry', ...
    'ROI_FLIPTR', ...
    'ClusterMean_mCherry', ...
    'ClusterMean_FLIPTR'});
%% ============================================================
% Save Results
%% ============================================================

save('lifetime_info.mat',...
    'LocalTable',...
    'Results',...
    'rois_fliptr',...
    'rois_mcherry',...
    'lt_scan_fliptr',...
    'lt_scan_mcherry',...
    'lt_scan_fliptr_x',...
    'lt_scan_fliptr_y',...
    'lt_scan_mcherry_x',...
    'lt_scan_mcherry_y',...
    'lt_scan_fliptr_xy',...
    'lt_scan_mcherry_xy');

writetable(Results,'ClusterResults.csv');
writetable(LocalTable,'WholeCell_5x5_LocalAnalysis.csv');
disp('Analysis completed successfully.');
disp('Results table saved as ClusterResults.csv');
disp('Workspace saved as lifetime_info.mat');



disp('Analysis completed successfully.');
disp('Results table saved as ClusterResults.csv');
disp('Workspace saved as lifetime_info.mat');
disp('==========================================');
disp('Lifetime analysis successfully completed.');
disp('Results saved to: lifetime_info.mat');
disp('==========================================');

disp('----------------------------------------');
disp('Lifetime analysis successfully saved.');
disp('Output file: lifetime_info.mat');
disp('----------------------------------------');



function rois = extractClusterROIs(image, centroids)
    % centroids: Nx2 matrix [x, y]
    % image: The source image
    % rois: 10x10xN matrix of extracted ROIs
    
    [imgH, imgW] = size(image);
    numClusters = size(centroids, 1);
    roiSize = 10;
    halfSize = roiSize / 2; % 5 pixels
    
    rois = zeros(roiSize, roiSize, numClusters);
    
    for i = 1:numClusters
        cx = round(centroids(i, 1));
        cy = round(centroids(i, 2));
        
        % Calculate boundaries
        x_start = cx - halfSize + 1;
        x_end   = cx + halfSize;
        y_start = cy - halfSize + 1;
        y_end   = cy + halfSize;
        
        % Check for image boundaries (Padding logic)
        % If the ROI goes outside the image, this implementation 
        % will skip it or you could add 'padarray' if you prefer.
        if x_start > 0 && x_end <= imgW && y_start > 0 && y_end <= imgH
            rois(:, :, i) = image(y_start:y_end, x_start:x_end);
        else
            warning('Cluster at [%d, %d] is too close to image edge. Skipping.', cx, cy);
        end
    end
end