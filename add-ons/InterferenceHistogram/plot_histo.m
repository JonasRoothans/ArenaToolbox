function plot_histo(fig, title_name,hit_list,name_list, cmap)
        figure(fig)
        b = bar(hit_list,'facecolor','flat');
        b.CData = cmap;
        title(title_name);
        ax = gca;
        set(ax,'XTickLabel',name_list);
        ax.FontSize =16
        xtickangle(40)
        ylim([0 105])
        ylabel('Percentage of fibers interfering with the lesion (%)');
end