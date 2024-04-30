function paired_plot_cceps(data1,data2,xtext1,xtext2,ytext)

% Paired t-test
[h, p, ci, stats] = ttest(data1, data2);

% Creating the plot
n = length(data1); % Number of pairs
for i = 1:n
    if isnan(data1(i)) || isnan(data2(i)), continue; end
    plot([1, 2], [data1(i), data2(i)], 'k-','linewidth',2); % Plot each pair with lines and markers
    hold on
end

% Formatting the plot
set(gca, 'XTick', [1, 2], 'XTickLabel', {xtext1, xtext2});
ylabel(ytext);
grid on;

% Displaying t-test results on the plot
title(sprintf('t = %.2f, p = %.3f', stats.tstat, p));


end