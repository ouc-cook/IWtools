function [xyRay] = raytraceOverCn(lon, lat, cn, xya0)
% [xyRay] = RAYTRACEOVERCN(lon, lat, cn, xya0)
%
%   inputs
%       - lon: longitude vector of the domain.
%       - lat: latitude    "    "   "     "
%       - cn: eigenspeed.
%       - xya0: 1x3 array with initial x/y positions and direction.
%
%   outputs
%       - xzRay: Nx2 with N coordinates of the ray. The first row is xy0.
%
% RAYTRACEOVERCN traces a shallow-water wave ray over the eigenspeed
% field "cn" specified at the rectangular grid defined by "lon" and
% "lat". The initial position of the ray and its angle of propagation
% (in radians) is given by xya0.
%
% The WKB approximation is used to derive the ray tracing equations.
% The traced ray may not be a realistic result if there are variations
% of cn at scales much smaller than the wavelength. The theoretical
% treatment can be found in Rainville and Pinkel (2006).
%
% TO DO:
%   - Need to sort out how to write the calculations
%     (and derivatives) on a sphere
%   - Trace in time.
%   - Could output more variables along the ray.
%
% Olavo Badaro Marques, 18/Oct/2017.


%%

wvfreq = 2*pi / (12.42*3600);

%
traceStep = 1;       
% % traceStep = 10 * 111;

%
nsteps = 300;
xyRay = NaN(nsteps+1, 2);


%%

Nlat = length(lat);
Nlon = length(lon);

%
[long, latg] = meshgrid(lon, lat);


%% Compute Coriolis parameter and its derivative (i.e. beta)

%
fvec = gsw_f(lat);

% Beta
omegaEarth = 7.292115e-5;
radiusEarth = 6.4e6;
betavec = 2 * omegaEarth * cosd(lat) ./ radiusEarth;


%%

f4ray = repmat(fvec(:), 1, length(lon));
b4ray = repmat(betavec(:), 1, length(lon));


%% Compute the derivative of the eigenspeed

%
cn_x = NaN(Nlat, Nlon);
cn_y = NaN(Nlat, Nlon);

%
cn_x(:, 2:end-1) = (cn(:, 3:end) - cn(:, 1:end-2)) ./ (long(:, 3:end) - long(:, 1:end-2));

cn_x(:, 1)   = (cn(:, 2) - cn(:, 1)) ./ (long(:, 2) - long(:, 1));
cn_x(:, end) = (cn(:, end) - cn(:, end-1)) ./ (long(:, end) - long(:, end-1));

%
cn_y(2:end-1, :) = (cn(3:end, :) - cn(1:end-2, :)) ./ (latg(3:end, :) - latg(1:end-2, :));

cn_y(1, :)   = (cn(2, :) - cn(1, :)) ./ (latg(2, :) - latg(1, :));
cn_y(end, :) = (cn(end, :) - cn(end-1, :)) ./ (latg(end, :) - latg(end-1, :));

% ------------------------------------------------------------
%       CHECK THE SIGNS OF THE DERIVATIVES!!!!!
% ------------------------------------------------------------
% ------------------------------------------------------------
%   NEED TO FIX THE UNITS OF THE DERIVATIVES OF CN
% ------------------------------------------------------------


%%

% ------------------------------------------------------------
% ------------------------------------------------------------
% ------------------------------------------------------------


%%

%
xyNow = [xya0(1), xya0(2)];
rayAng = xya0(3);

%
cnpt = interp2(lon, lat, cn, xyNow(1), xyNow(2));
cppt = cn2cpcg(cnpt, wvfreq * 24*3600/(2*pi), xyNow(2));

%
pxpyNow = [ cos(rayAng)/cppt, ...
            sin(rayAng)/cppt ];


%
xyRay(1, :) = xyNow;


%%

for i = 1:nsteps
    
    
    %% --------------------------------------------------------------------
    % Trace next point on the ray:
    xyTrc(1) = xyNow(1) + (traceStep .* cos(rayAng));
    xyTrc(2) = xyNow(2) + (traceStep .* sin(rayAng));
       
    xyNow = xyTrc;
    
    % Assign new coordinates to output variable
    xyRay(i+1, :) = xyNow;
    
    
    %% --------------------------------------------------------------------

    % If current point is outside the domain, then break the loop
    if not((xyNow(1)>=lon(1) && xyNow(1)<=lon(end)) && ...
           (xyNow(2)>=lat(1) && xyNow(2)<=lat(end)))
       
        warning('Ray left the domain')
        break
    end
    
    
    %%
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    %     
    % ---------------------------------------------------------------------
    % ---------------------------------------------------------------------
    
    %% --------------------------------------------------------------------
    
    %
    cnpt = interp2(lon, lat, cn, xyNow(1), xyNow(2));
    cppt = cn2cpcg(cnpt, wvfreq * 24*3600/(2*pi), xyNow(2));
    
    %
    fpt = interp2(lon, lat, f4ray, xyNow(1), xyNow(2));
    
    %
    bpt = interp2(lon, lat, b4ray, xyNow(1), xyNow(2));
    
    
    %% --------------------------------------------------------------------
    
    % For angles closer to ZONAL
    if abs(tan(rayAng)) <= 30
        
        %
        dcndy = interp2(lon, lat, cn_y, xyNow(1), xyNow(2));
        
        % Equation (18) in Rainville's 2006
        dpydxNow = - (1 / ((cnpt * wvfreq)^2 * pxpyNow(1))) * ...
                     ( (pxpyNow(1)^2 + pxpyNow(2)^2)*(cnpt*dcndy)*wvfreq^2  + fpt*bpt);
        
        %
        pxpyNow(2) = pxpyNow(2) + ( (111000 * cos(fpt)) * dpydxNow * (traceStep .* cos(rayAng)) );
%         pxpyNow(2) = pxpyNow(2) + ( (111000) * dpydxNow * (traceStep .* cos(rayAng)) );
        
        % Equivalent but different ways to do it!!!
        pxpyNow(1) = sqrt((1/cppt)^2 - pxpyNow(2)^2);   % SQRT WILL COMPLICATE WESTWARD TRAVELLING WAVES
% %         pxpyNow(1) = cos(rayAng) / cppt;	% I THINK THIS FORMAT IS POINTLESS
        
        % --------------------------------------------------------------
        % NEED TO FIX MAKE UNITS CONSISTENT WHEN UPDATING pxpyNow(2)
        % --------------------------------------------------------------

%         if i>=1
%             pxpyNow
%             keyboard
%         end


	% For angles closer to MERIDIONAL
    else
        
        %
        dcndx = interp2(lon, lat, cn_x, xyNow(1), xyNow(2));
        
        %
        dpxdyNow = - 1/(pxpyNow(2)*cppt^3) * (wvfreq/sqrt(wvfreq^2 - fpt^2)) * dcndx;
        
        %
        pxpyNow(1) = pxpyNow(1) + ( 111000 * dpxdyNow * (traceStep .* sin(rayAng)) );

        %
% %         pxpyNow(2) = sin(rayAng) / cppt;
        
        pxpyNow(2) =  sign(sin(rayAng)) * sqrt((1/cppt)^2 - pxpyNow(1)^2);
        
        if ~isreal(pxpyNow)
            keyboard
        end
        
    end
    

    %% --------------------------------------------------------------------
    
    % Update the ray angle
    rayAng = atan2(pxpyNow(2), pxpyNow(1));
    
    
    %%
%     keyboard
end


%%

% ------------------------------------------------------------
% ------------------------------------------------------------
% ------------------------------------------------------------

% % % ------------------------------------------------------------
% % % function dpydx
% % % 
% % % end
% % 
% % % % ------------------------------------------------------------
% % % function dpydx
% % % 
% % % end



