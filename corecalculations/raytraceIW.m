function [xzr] = raytraceIW(xg, zg, N, f0, wvf, xz0, rayQuad, traceDx)
% [xzr] = RAYTRACEIW(xg, zg, N2, f0, wvf, xz0)
%
%   inputs:
%       - xg: horizontal grid points.
%       - zg: vertical grid points.
%       - N: matrix of size (length(zg))x(length(xg)) with the buoyancy
%            frequency, in radians per second. NaNs in the matrix are
%            interpreted as solid boundary.
%       - f0: Coriolis parameter in radians per second.
%       - wvf: wave frequency, in radians per second.
%       - xz0: 1x2 vector with initial (x, z) coordinates of the wave group.
%       - pointDir:
%
%   outputs:
%       - xzr: Nx2 with N coordinates of the ray.
%              xzr(1, :) is always equal to xz0.
%
%
% The tangent (dz/dx) of the ray is giving by the dispersion relationship:
% dz/dx = +- sqrt((wvf^2 - f0^2) / (N^2 - wvf^2))
%
% TO DO:
%   - The grid resolution gives me angle resolution of tracing. Use
%     that as a diagnostic.
%   - Trace "in time"????
%   - Later take a look at asymptotic expansion for turning depths.
%   - It could be nice to deal with wavenumber of fake magnitude (but
%     correct), which could allow me use some linear algebra and write a
%     better code.
%   - DISTANCE, X AND Z WITH DIFFERENT SCALES (!!!!)
%
% The while loop may make the code more synthetic if I first store the ray
% location and then trace it, leaving the next point for subsequent
% iteration.
%
% Olavo Badaro Marques, 14/Feb/2017.

% There is some arbitrariness on the ray location with respect to grid
% points. Some possibilities are:
%   - Trace in time and interpolate N at every time step. That may be good
%  	choosing a small time step, but a long one will give wrong results.
%   - Approximate ray locations by the grid points (what I'm currently
%   doing, but then I have to case about how far the rays are from grid
%   points).
%
% SHOULD ADD NANS AS THE FIRST ROW OF N SUCH THAT THE SURFACE CAN BE
% TREATED AS FLAT BOUNDARY??? THE CODE FOR DOING REFLECTION OFF OF THE
% SURFACE AND THE BOTTOM WOULD THEN BE THE SAME


%% Create a Nx2 matrix with all the N grid point coordinates:

[xgmesh, ygmesh] = meshgrid(xg, zg);

gridPoints = [xgmesh(:), ygmesh(:)];


%%


if ~exist('traceDx', 'var')
    
    % traceDx = median(diff(xg));   % use xg, because this is much larger in
                                    % the ocean than zg, and rays propagate
                                    % mostly horizontally
    traceDx = 1000;

end
    



%%

xzNow = xz0;

linGrid = (xzNow(1)>=xg(1) && xzNow(1)<=xg(end) && ...
           xzNow(2)>=zg(1) && xzNow(2)<=zg(end));

indRay = zeros(1, size(gridPoints, 1));
xzr = NaN(length(indRay), 2);

% indclosest = dsearchn(gridPoints, xzNow(:));
% indRay(1) = indclosest;
xzr(1, :) = xzNow;

% xzNow = gridPoints(indclosest, :);

% -------------------------------------------------------
% I DO NOT WANT TO INTERPOLATE OVER NANS!!!!!
auxNprof = interp1overnans(xg, N', xzNow(1));
auxNprof = auxNprof';

TrcN2 = interp1(zg, auxNprof, xzNow(2));
% -------------------------------------------------------

xzTrc = NaN(1, 2);
%
i = 2;

while linGrid
    
    rayTan = abs( sqrt((wvf^2 - f0^2)/(TrcN2^2 - wvf^2)) );
    
    rayAng = atan(rayTan);  % the above with always gives an
                            % angle in the first quadrant
    
%     % Check direction
%     if rayQuad(1)<0
%         
%     end
    xzTrc(1) = xzNow(1) + traceDx .* cos(rayAng);
    xzTrc(2) = xzNow(2) + traceDx .* sin(rayAng);
    
    linGrid = (xzTrc(1)>=xg(1) && xzTrc(1)<=xg(end) && ...
               xzTrc(2)>=zg(1) && xzTrc(2)<=zg(end));
    
	[linX, linZ] = checklGrid(xg([1 end]), zg([1 end]), xzTrc);
           
	
    if linX && linZ
        
        
        % -------------------------------------------------------
        % I DO NOT WANT TO INTERPOLATE OVER NANS!!!!!
        auxNprof = interp1overnans(xg, N', xzTrc(1));
        auxNprof = auxNprof';
        
        TrcN2 = interp1(zg, auxNprof, xzTrc(2));
        % -------------------------------------------------------


%         indRay(i) = indclosest;   % probably useless now
        
        xzr(i, :) = xzTrc;

        xzNow = xzTrc;
        i = i + 1;
        
        
    else
        
        % For now, break tracing when ray leaves the
        % domain THROUGH ANY SIDES OF DOMAIN
        
        break
        
        
    end
           
%     indclosest = dsearchn(gridPoints, xzNow(:));
    
end



%%

xzr = xzr(~isnan(xzr(:, 1)), :);



end


%% -----------------------------------------------------------------
% ------------------------------------------------------------------
% ------------------------------------------------------------------

function [linX, linZ] = checklGrid(xglims, zglims, xzpt)
    %%
    
    linX = (xzpt(1) >= xglims(1)) && (xzpt(1) <= xglims(2));
    
    linZ = (xzpt(2) >= zglims(1)) && (xzpt(2) <= zglims(2));
    


end


