function eta = linearDisplacement(zxp, xp, zxB, xB, cutoff)
% eta = LINEARDISPLACEMENT(zxp, xp, zxB, xB, cutoff)
%
%   inputs:
%       - zxp: depth vector associated with xp.
%       - xp: x "prime", i.e. the variability relative to a background.
%       - zxB: depth vector for xB
%       - xB: x background profile.
%       - cutoff (optional): minimum threshold for dXBdz (default is 0,
%                            which is the same as no threshold).  
%
%   outputs:
%       - eta: vertical displacement.
%
% Compute linear vertical displacement of the quantity required to
% explain the anomaly xp based on the vertical gradient of the
% background profile xB.
%
%
% TO DO:
%   - I should include some check for non-monotonically
%     increasing/decreasing background profiles.
%   - MAYBE TO DO: sort zxB?
%
% Olavo Badaro Marques, 02/05/2017.


%% If no cutoff input is given, then select default value

if ~exist('cutoff', 'var')
    cutoff = 0;
end


%% Take the sign difference of the top to bottom difference,
% this will be used to determine if a positive anomaly
% corresponds to a positive or negative displacement

gradSign = sign(zxB(end) - zxB(1));


%% Take the derivative of xB

dxBdz = (xB(2:end) - xB(1:end-1)) ./ diff(zxB);

zdxBdz = (zxB(1:end-1) + zxB(2:end))/2;


%% Interpolate the derivative of xB onto the same grid (zxp) as xp

dxBatXp = interp1(zdxBdz, dxBdz, zxp);
    
dxBatXp = repmat(dxBatXp, 1, size(xp, 2));


%% Compute vertical displacement

eta = xp ./ dxBatXp;


%% Final modifications to eta

% Remove values associated with dXBdz below cutoff:
lcut = (abs(dxBatXp) < abs(cutoff));
eta(lcut) = NaN;

% Multiply eta by -1 or + 1 depending on whether xB
% increases or decreases (respectively) with depth:
eta = gradSign * eta; 


