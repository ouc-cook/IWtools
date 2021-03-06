function [xyRay, cnRay, angRay] = raytraceOverCn(lon, lat, cn, xya0, dtN)
% [xyRay, cnRay, angRay] = RAYTRACEOVERCN(lon, lat, cn, xya0, dtN)
%
%   inputs
%       - lon: longitude vector of the domain.
%       - lat: latitude    "    "   "     "
%       - cn: eigenspeed field (for every lon/lat coordinate).
%       - xya0: 1x3 array with initial x/y positions and direction.
%       - dtN: 1x2 array with time resolution and
%              total number of time steps.
%
%   outputs
%       - xzRay: Nx2 with N coordinates of the ray. The first row is xy0.
%       - cnRay: Nx1 array with eigenspeeds along the ray.
%       - angRay:
%
% RAYTRACEOVERCN traces a shallow-water wave ray over the eigenspeed
% field "cn" specified at the rectangular grid defined by "lon" and
% "lat". The initial position of the ray and its angle of propagation
% (in radians) is given by xya0.
%
% The WKB approximation is used to derive the ray tracing equations.
% The traced ray may not be a realistic result if there are significant
% variations of cn at scales comparable or much smaller than the
% wavelength. The theoretical treatment can be found in Rainville and
% Pinkel (2006).
%
% TO DO:
%   - Trace in time.
%   - Could output more variables along the ray.
%
% Olavo Badaro Marques, 18/Oct/2017.


%%

wvfreq = 2*pi / (12.42*3600);

%
dt = dtN(1);
nsteps = dtN(2);

%
xyRay = NaN(nsteps+1, 2);
cnRay = NaN(nsteps+1, 1);
angRay = NaN(nsteps+1, 1);


%%

Nlat = length(lat);
Nlon = length(lon);

%
[long, latg] = meshgrid(lon, lat);


%% If cn is a number, then create an array
% (correspondent with cn constant in space)

if isscalar(cn)
	cn = cn .* ones(Nlat, Nlon); 
end


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


%% Compute the spatial derivatives of the eigenspeed field

%
cn_x = NaN(Nlat, Nlon);
cn_y = NaN(Nlat, Nlon);

%
dlon_1 = distance(latg(:, 1:end-2), long(:, 1:end-2), ...
                  latg(:, 3:end), long(:, 3:end));
dlon_2 = distance(latg(:, 1), long(:, 1), ...
                  latg(:, 2), long(:, 2));
dlon_3 = distance(latg(:, end-1), long(:, end-1), ...
                  latg(:, end), long(:, end));
              
dlon_1 = 1000 * deg2km(dlon_1);
dlon_2 = 1000 * deg2km(dlon_2);
dlon_3 = 1000 * deg2km(dlon_3);

cn_x(:, 2:end-1) = (cn(:, 3:end) - cn(:, 1:end-2)) ./ dlon_1;
cn_x(:, 1)   = (cn(:, 2) - cn(:, 1)) ./ dlon_2;
cn_x(:, end) = (cn(:, end) - cn(:, end-1)) ./ dlon_3;

%
dlat_1 = distance(latg(1:end-2, :), long(1:end-2, :), latg(3:end, :), long(3:end, :));
dlat_2 = distance(latg(1, :), long(1, :), latg(2, :), long(2, :));
dlat_3 = distance(latg(end-1, :), long(end-1, :), latg(end, :), long(end, :));
              
dlat_1 = 1000 * deg2km(dlat_1);
dlat_2 = 1000 * deg2km(dlat_2);
dlat_3 = 1000 * deg2km(dlat_3);

cn_y(2:end-1, :) = (cn(3:end, :) - cn(1:end-2, :)) ./ dlat_1;
cn_y(1, :)   = (cn(2, :) - cn(1, :)) ./ dlat_2;
cn_y(end, :) = (cn(end, :) - cn(end-1, :)) ./ dlat_3;

% ------------------------------------------------------------
%       CHECK THE SIGNS OF THE DERIVATIVES (probably right)
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
[cppt, cgpt] = cn2cpcg(cnpt, wvfreq * 24*3600/(2*pi), xyNow(2));

%
pxpyNow = [ cos(rayAng)/cppt, ...
            sin(rayAng)/cppt ];

%
xyRay(1, :) = xyNow;
cnRay(1) = cnpt;
angRay(1) = rayAng;


%%

traceStep = (cgpt * dt) / 111000;


%%

for i = 1:nsteps
    
    %% --------------------------------------------------------------------
    % Trace next point on the ray:
    xyTrc(1) = xyNow(1) + (traceStep .* cos(rayAng));
    xyTrc(2) = xyNow(2) + (traceStep .* sin(rayAng));
    
    [xyTrc(2), xyTrc(1)] = reckon(xyNow(2), xyNow(1), traceStep, 90 - (180*rayAng/pi));    
     
    %
    xyTrc(1) = wrapPhase([0, 360], xyTrc(1));
    
    %
    xyNow = xyTrc;
    
    % Assign new coordinates to output variable
    xyRay(i+1, :) = xyNow;
    angRay(i+1) = rayAng;
    

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
    [cppt, cgpt] = cn2cpcg(cnpt, wvfreq * 24*3600/(2*pi), xyNow(2));
    
    %
    fpt = interp2(lon, lat, f4ray, xyNow(1), xyNow(2));
    
    %
    bpt = interp2(lon, lat, b4ray, xyNow(1), xyNow(2));
    
    %
    cnRay(i+1) = cnpt;
        
    %%
	traceStep = (cgpt * dt) / 111000;
    
    
    %%
    
    %
    dcndy = interp2(lon, lat, cn_y, xyNow(1), xyNow(2));
    dcndx = interp2(lon, lat, cn_x, xyNow(1), xyNow(2));
    
    % Equation (18) in Rainville's 2006
    dpydxNow = - (1 / ((cnpt * wvfreq)^2 * pxpyNow(1))) * ...
                 ( (pxpyNow(1)^2 + pxpyNow(2)^2)*(cnpt*dcndy)*wvfreq^2  + fpt*bpt);
    
	% Two expressions are (should be) equivalent
% %         dpxdyNow = - 1/(pxpyNow(2)*cppt^3) * (wvfreq/sqrt(wvfreq^2 - fpt^2)) * dcndx;
    dpxdyNow = - (pxpyNow(1)^2 + pxpyNow(2)^2) * (1/(cnpt*pxpyNow(2))) * dcndx;

    if abs(tan(rayAng)) <= 2
        %
        py_aux = pxpyNow(2) + ( (111000) * dpydxNow * (traceStep .* cos(rayAng)) );
        px_aux = sign(cos(rayAng)) * sqrt((1/cppt)^2 - pxpyNow(2)^2);
        
        %
        l_zonaleqs = true;
    else
        %
        px_aux = pxpyNow(1) + ( 111000 * dpxdyNow * (traceStep .* sin(rayAng)) );
        py_aux =  sign(sin(rayAng)) * sqrt((1/cppt)^2 - pxpyNow(1)^2);
        
        %
        l_zonaleqs = false;
    end
    
    %
    if ~isreal(px_aux) || ~isreal(py_aux)
     
        %
        if l_zonaleqs
            
            %
            px_aux = pxpyNow(1) + ( 111000 * dpxdyNow * (traceStep .* sin(rayAng)) );
            py_aux =  sign(sin(rayAng)) * sqrt((1/cppt)^2 - pxpyNow(1)^2);
        else
            %
            py_aux = pxpyNow(2) + ( (111000) * dpydxNow * (traceStep .* cos(rayAng)) );
            px_aux = sign(cos(rayAng)) * sqrt((1/cppt)^2 - pxpyNow(2)^2);
        end
        
    end
    
    %
    if ~isreal(px_aux) || ~isreal(py_aux)
        warning('***oh no...***')
        keyboard
    end
    
    %
    pxpyNow(1) = px_aux;
    pxpyNow(2) = py_aux;
    rayAng = atan2(pxpyNow(2), pxpyNow(1));
   
    
% %     %% --------------------------------------------------------------------
% %     
% %     % For angles closer to ZONAL
% %     if abs(tan(rayAng)) <= 2
% %         
% %         %
% %         dcndy = interp2(lon, lat, cn_y, xyNow(1), xyNow(2));
% %         
% %         % Equation (18) in Rainville's 2006
% %         dpydxNow = - (1 / ((cnpt * wvfreq)^2 * pxpyNow(1))) * ...
% %                      ( (pxpyNow(1)^2 + pxpyNow(2)^2)*(cnpt*dcndy)*wvfreq^2  + fpt*bpt);
% %         if i==49
% %             keyboard
% %         end
% %         %
% % %         pxpyNow(2) = pxpyNow(2) + ( (111000*cos(xyNow(2))) * dpydxNow * (traceStep .* cos(rayAng)) );
% %         pxpyNow(2) = pxpyNow(2) + ( (111000) * dpydxNow * (traceStep .* cos(rayAng)) );
% %         
% %         %
% %         pxpyNow(1) = sign(cos(rayAng)) * sqrt((1/cppt)^2 - pxpyNow(2)^2);   % SQRT WILL COMPLICATE WESTWARD TRAVELLING WAVES
% % 
% % % %         if ~isreal(pxpyNow)
% % % %             keyboard
% % % %         end
% %         
% % 	% For angles closer to MERIDIONAL
% %     else
% %         
% %         %
% %         dcndx = interp2(lon, lat, cn_x, xyNow(1), xyNow(2));
% %         
% %         % Two expressions are (should be) equivalent
% % % %         dpxdyNow = - 1/(pxpyNow(2)*cppt^3) * (wvfreq/sqrt(wvfreq^2 - fpt^2)) * dcndx;
% %         dpxdyNow = - (pxpyNow(1)^2 + pxpyNow(2)^2) * (1/(cnpt*pxpyNow(2))) * dcndx;
% %         
% %         %
% %         pxpyNow(1) = pxpyNow(1) + ( 111000 * dpxdyNow * (traceStep .* sin(rayAng)) );
% % 
% %         %        
% %         pxpyNow(2) =  sign(sin(rayAng)) * sqrt((1/cppt)^2 - pxpyNow(1)^2);
% % 
% %         
% % % %         if ~isreal(pxpyNow)
% % % %             keyboard
% % % %         end
% %         
% %     end
% %     
% % 
% %     %% --------------------------------------------------------------------
% %     
% %     % Update the ray angle
% %     rayAng = atan2(pxpyNow(2), pxpyNow(1));
    
    

end


