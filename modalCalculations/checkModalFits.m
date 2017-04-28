function checkModalFits(z, x, vmodes, zmds, lpltRecons, lpltAmp)
% CHECKMODALFITS(z, x, vmodes, zmds, lpltRecons, lpltAmp)
%
%   inputs:
%       - z: vertical coordinate of the data
%       - x: data to decompose into vertical modes.
%       - vmodes: MxN modal shape matrix with N modes.
%       - zmds (optional):
%       - lpltRecons: logical value for the reconstruction plot
%       - lpltAmp: logical value for the amplitude versus fit modes plot.
%
% Plot modal amplitude as a function
%
%   PLOTS.... but I could give the data in the plots as outputs...
%
%   I SHOULD PROBABLY INCLUDE COMPUTING THE MODES INSIDE....BECAUSE
%   THIS PLOT IS ONLY GOOD FOR FITTING LOTS OF MODES, WHICH WE DO
%   NOT DO ALL THE TIME.
%
% Olavo Badaro Marques, 09/Nov/2016


%% Maximum vectors we will look at, just
% to avoid making a sheer number of plots:

nvecs = size(x, 2);

maxnvec = 5;

if nvecs > maxnvec
    error('Too many vectors to make fits.')
end

nmds = size(vmodes, 2);


%% If logical inputs are not give, assign true for both of them:

if ~exist('lpltRecons', 'var') || isempty(lpltRecons)
    lpltRecons = true;
end

if ~exist('lpltAmp', 'var') || isempty(lpltRecons)
    lpltRecons = true;
end


%% 

% there should be a big loop below for going over the columns x...


%%


mdsAmp = NaN(nmds);

if ~exist('zmds', 'var') || isempty(zmds)
    zmds = z;
end

for i = 1:nmds
    
    mdsAmp(1:i, i) = fitVmodes(z, x, vmodes(:, 1:i), zmds);
    
end


%%


if lpltRecons
    
    %
%     absmax = max(max(mdsAmp));
%     absmin = min(min(mdsAmp));
%     
%     allrange = absmax - absmin;

    % Goes to the figure and loop through modes:
    figure
        hold on
        plot(x, z, 'k', 'LineWidth', 2)
        grid on, box on
        axis ij
        set(gca, 'FontSize', 14)

        for i = 1:nmds
            
            reconsaux = mdsAmp(1:i, i)' * vmodes(:, 1:i)';
            plot(reconsaux, zmds, 'LineWidth', 1.5)
            
%             axis([0 nmds+1 absmin-(0.1*allrange) absmax+(0.1*allrange)])            

            pause(1)
        end
        
	% Compare the data with the fit with all the modes:
	figure
        hold on
        plot(x, z, 'k', 'LineWidth', 2)
        grid on, box on
        axis ij
        set(gca, 'FontSize', 14)
        plot(reconsaux, zmds, 'LineWidth', 1.5)
        
    
    
end


%%


if lpltAmp
    
    % Create color pallete for the amplitude with different modes:
%     colorpal = [zeros()]
    
    %
    absmax = max(max(mdsAmp));
    absmin = min(min(mdsAmp));
    
    allrange = absmax - absmin;

    % Goes to the figure and loop through modes:
    figure
        hold on
        for i = 1:nmds
            plot(1:nmds, mdsAmp(:, i), '.', 'MarkerSize', 40)
            plot(1:nmds, mdsAmp(:, i), '--', 'Color', [0.5 0.5 0.5])
            axis([0 nmds+1 absmin-(0.1*allrange) absmax+(0.1*allrange)])
            grid on
            box on
            set(gca, 'FontSize', 14)
            xlabel('Modes (as given by the columns of input vmodes)', 'FontSize', 14)
            ylabel('Amplitude', 'FontSize', 14)
            
            pause(1)
        end
           
	%
    maxsubplt = 5;
    if nmds >= maxsubplt
        nsubplts = 5;
    else
        nsubplts = nmds;
    end
    
	figure
        set(gcf, 'Units', 'normalized', 'Position', [0.4 0.1 0.4 0.9])
        for i = 1:nsubplts
            subplot(nsubplts, 1, i)
                plot(1:nmds, mdsAmp(i, :), '.k', 'MarkerSize', 40)
                grid on
                box on
                set(gca, 'FontSize', 14)
                title(['Mode in column ' num2str(i)], 'FontSize', 16)
                
                % Set y axis limits:
                modesignaux = sign(mdsAmp(i, :));
                modesignaux = modesignaux(~isnan(modesignaux));
                
                xlim([0 nmds+1])
                
                if ~all(modesignaux==modesignaux(1))
                    warning(['Amplitude estimate of mode in ' ...
                             'column ' num2str(i) ' changes sign'])
                else
                    
                    absmaxamp = max(abs(mdsAmp(i, :)));
                    
                    if modesignaux(1)==-1
                        
                        ylim([-1.1*absmaxamp 0])
                    else
                        ylim([0 1.1*absmaxamp])
                    end  
                end
                
                % Set y axis ticks:
                auxylim = ylim;
                set(gca, 'YTick', linspace(auxylim(1), auxylim(2), 4))
                set(gca, 'YTickLabel', sprintf('%.3f \n', get(gca, 'YTick')))
  
        end
        
        
end



%%
