function out = curvature5x5_cubicFit(Z, dx)
% Fits cubic surface to 5x5 patch and classifies by shape index.
% Reference: Koenderink & van Doorn, Image and Vision Computing, 1992.
% DOI: 10.1016/0262-8856(92)90060-3

if nargin < 2
    dx = 1;
end

if ~isequal(size(Z), [5 5])
    error('Input Z must be a 5x5 matrix');
end

Z = double(Z);

[x, y] = meshgrid(-2:2, -2:2);
x = x * dx;
y = y * dx;

xv = x(:);
yv = y(:);
zv = Z(:);

% Cubic surface:
% z = ax3 + by3 + cx2y + dxy2 + ex2 + fy2 + gxy + hx + iy + j
A = [xv.^3, yv.^3, xv.^2.*yv, xv.*yv.^2, ...
     xv.^2, yv.^2, xv.*yv, xv, yv, ones(size(xv))];

coef = A \ zv;

a = coef(1); b = coef(2); c = coef(3); d = coef(4);
e = coef(5); f = coef(6); g = coef(7);
h = coef(8); ii = coef(9); j = coef(10);

% Derivatives at centre
zx  = h;
zy  = ii;
zxx = 2*e;
zyy = 2*f;
zxy = g;

D = 1 + zx^2 + zy^2;

H = ((1 + zy^2)*zxx - 2*zx*zy*zxy + (1 + zx^2)*zyy) / ...
    (2 * D^(3/2));

K = (zxx*zyy - zxy^2) / D^2;

disc = max(H^2 - K, 0);
k1 = H + sqrt(disc);
k2 = H - sqrt(disc);

% Ensure k1 >= k2
if k1 < k2
    temp = k1;
    k1 = k2;
    k2 = temp;
end

%% Shape index and curvedness

curvedness = sqrt((k1^2 + k2^2)/2);
signedCurvedness = sign(H) * curvedness;

% Scale-aware tolerance
relTol = 0.01;              % 1% of curvature magnitude
absTol = 1e-8;              % safety floor
tol = max(absTol, relTol * curvedness);

if curvedness < tol
    shapeIndex = NaN;
    cls = "FLAT";
    simpleCls = "flat";
else
    denom = k1 - k2;

    if abs(denom) < eps
        shapeIndex = sign(H);
    else
        shapeIndex = (2/pi) * atan((k1 + k2) / denom);
    end

    % Koenderink-style shape-index bins
    if shapeIndex <= -2/3
        cls = "CUP / PIT";
        simpleCls = "cup";
    elseif shapeIndex > -2/3 && shapeIndex <= -1/3
        cls = "TROUGH";
        simpleCls = "trough";
    elseif shapeIndex > -1/3 && shapeIndex < 1/3
        cls = "SADDLE";
        simpleCls = "saddle";
    elseif shapeIndex >= 1/3 && shapeIndex < 2/3
        cls = "RIDGE";
        simpleCls = "ridge";
    elseif shapeIndex >= 2/3
        cls = "DOME / HILL";
        simpleCls = "dome";
    else
        cls = "UNCLASSIFIED";
        simpleCls = "unclassified";
    end
end

%% Fit values and goodness of fit

Zfit5 = reshape(A * coef, 5, 5);
residuals = Z - Zfit5;

SSE = sum(residuals(:).^2);
SST = sum((Z(:) - mean(Z(:))).^2);
RMSE = sqrt(mean(residuals(:).^2));

if SST > 0
    R2 = 1 - SSE/SST;
else
    R2 = NaN;
end

n = numel(Z);
p = numel(coef);

adjustedR2 = 1 - (1 - R2) * (n - 1) / (n - p - 1);

%% Fine surface for visualization

[xfine, yfine] = meshgrid(linspace(-2,2,75)*dx, linspace(-2,2,75)*dx);

ZfitFine = a*xfine.^3 + b*yfine.^3 + ...
           c*xfine.^2.*yfine + d*xfine.*yfine.^2 + ...
           e*xfine.^2 + f*yfine.^2 + g*xfine.*yfine + ...
           h*xfine + ii*yfine + j;

%% Extra height-based diagnostics only, not classification

centreHeight = Z(3,3);
neighbourMean = mean([Z(2,3), Z(4,3), Z(3,2), Z(3,4)]);
deltaCentreNeighbour = centreHeight - neighbourMean;

%% Output

out.k1 = k1;
out.k2 = k2;
out.meanCurvature = H;
out.gaussianCurvature = K;

out.shapeIndex = shapeIndex;
out.curvedness = curvedness;
out.signedCurvedness = signedCurvedness;

out.classification = cls;
out.simpleClassification = simpleCls;

out.coefficients = coef;
out.coefficientNames = {'x3','y3','x2y','xy2','x2','y2','xy','x','y','constant'};

out.X = x;
out.Y = y;
out.Z = Z;

out.Zfit5 = Zfit5;
out.residuals = residuals;

out.Xfine = xfine;
out.Yfine = yfine;
out.ZfitFine = ZfitFine;

out.centreHeight = centreHeight;
out.neighbourMean = neighbourMean;
out.deltaCentreNeighbour = deltaCentreNeighbour;

out.goodness.SSE = SSE;
out.goodness.RMSE = RMSE;
out.goodness.R2 = R2;
out.goodness.adjustedR2 = adjustedR2;
out.goodness.toleranceUsed = tol;

end