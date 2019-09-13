function PlotLightmap(lightmap, x_axis_sz, y_axis_sz, ax)
    % plot 3d scatter of light levels above field
    
    % find and delete old 3d scatter
    s3 = findobj('type', 'scatter3');
    delete(s3);
    
    % 3D scatter light level points above plane
    hold on;
    scatter3(ax, lightmap(:, 1), lightmap(:, 2), lightmap(:, 3));
    xlim([0, x_axis_sz]);
    ylim([0, y_axis_sz]);
    view(105,30);
    axis square;
    grid on;
    % Done plotting
    hold off;
end