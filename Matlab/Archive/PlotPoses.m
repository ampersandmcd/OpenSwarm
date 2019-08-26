function f = PlotLocations(positions, goto_matrix, x_axis_sz, y_axis_sz, ax)
    % separate current heading vectors by quadrant
    q1 = (positions(:,3) <= 90);
    q2 = (positions(:,3) > 90)  .* (positions(:,3) <= 180);
    q3 = (positions(:,3) > 180) .* (positions(:,3) <= 270);
    q4 = (positions(:,3) > 271) .* (positions(:,3) <= 360);
    
    % separate goto heading vectors by quadrant
    g1 = (goto_matrix(:,3) <= 90);
    g2 = (goto_matrix(:,3) > 90)  .* (goto_matrix(:,3) <= 180);
    g3 = (goto_matrix(:,3) > 180) .* (goto_matrix(:,3) <= 270);
    g4 = (goto_matrix(:,3) > 271) .* (goto_matrix(:,3) <= 360);

    scale_factor = 50;
    hold on;
    cla(ax);
    % plot current positions & headings of robots
    scatter(ax, positions(:, 1), positions(:, 2), 'blue');
	current_labels = num2str((1:size(positions, 1))', '%d');
    text(positions(:, 1) + 10, positions(:, 2) + 10, current_labels, 'horizontal','left', 'vertical','bottom');
    quiver(ax, positions(q1 == 1,1), positions(q1 == 1,2), scale_factor * cos(positions(q1 == 1,3) * pi/180), scale_factor * sin(positions(q1 == 1,3) * pi/180), 'Color', [0 0 1]);
    quiver(ax, positions(q2 == 1,1), positions(q2 == 1,2), scale_factor * cos(positions(q2 == 1,3) * pi/180), scale_factor * sin(positions(q2 == 1,3) * pi/180), 'Color', [0 0 1]); % sin is negative in 2nd quadrant
    quiver(ax, positions(q3 == 1,1), positions(q3 == 1,2), scale_factor * cos(positions(q3 == 1,3) * pi/180), scale_factor * sin(positions(q3 == 1,3) * pi/180), 'Color', [0 0 1]);
    quiver(ax, positions(q4 == 1,1), positions(q4 == 1,2), scale_factor * cos(positions(q4 == 1,3) * pi/180), scale_factor * sin(positions(q4 == 1,3) * pi/180), 'Color', [0 0 1]); % cos is negative in 4th quadrant
    
    % plot goto positions & headings of robots
    scatter(ax, goto_matrix(:, 1), goto_matrix(:, 2), 'red');
    goto_labels = num2str((1:size(goto_matrix, 1))', '%d');
    text(goto_matrix(:, 1) + 10, goto_matrix(:, 2) + 10, goto_labels, 'horizontal','left', 'vertical','bottom');
    quiver(ax, goto_matrix(g1 == 1,1), goto_matrix(g1 == 1,2), scale_factor * cos(goto_matrix(g1 == 1,3) * pi/180), scale_factor * sin(goto_matrix(g1 == 1,3) * pi/180), 'Color', [1 0 0]);
    quiver(ax, goto_matrix(g2 == 1,1), goto_matrix(g2 == 1,2), scale_factor * cos(goto_matrix(g2 == 1,3) * pi/180), scale_factor * sin(goto_matrix(g2 == 1,3) * pi/180), 'Color', [1 0 0]); % sin is negative in 2nd quadrant
    quiver(ax, goto_matrix(g3 == 1,1), goto_matrix(g3 == 1,2), scale_factor * cos(goto_matrix(g3 == 1,3) * pi/180), scale_factor * sin(goto_matrix(g3 == 1,3) * pi/180), 'Color', [1 0 0]);
    quiver(ax, goto_matrix(g4 == 1,1), goto_matrix(g4 == 1,2), scale_factor * cos(goto_matrix(g4 == 1,3) * pi/180), scale_factor * sin(goto_matrix(g4 == 1,3) * pi/180), 'Color', [1 0 0]); % cos is negative in 4th quadrant
    
    xlim([0, x_axis_sz]);
    ylim([0, y_axis_sz]);
    % Done plotting
    hold off;
end