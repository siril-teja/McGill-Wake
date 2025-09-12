cd('C:\Users\emmac\Documents\arcmap_cli_v1_0_0rc2\example_datasets\McGill_WF_SPM')
tvals=linspace(0,165,(165/15)+1);
styles={'-','--',':'};
specs = {'Surrogate1', 'Surrogate2', 'Surrogate3', 'Sawbones'};
for p=1:length(tvals)
    figure;
    hold on;
    % Wake Forest
    cd(['WF_',num2str(tvals(p))])
    WF_list = dir('*.csv')
    for w=1:length(WF_list)
        WF=readmatrix(WF_list(w).name);
        plot(WF(:,1),WF(:,2),'Color',[140 109 44]./255,'LineStyle',string(styles(w)),'LineWidth', 2,'DisplayName',strcat('WF ',string(specs(w))))
        hold on;
    end
  
    % McGill
    cd ..
    cd(['MG_',num2str(tvals(p))])
    MG_list = dir('*.csv')
    for m=1:length(MG_list)
        MG=readmatrix(MG_list(m).name);
        plot(MG(:,1),MG(:,2),'Color',[248 32 33]./255,'LineStyle',string(styles(m)),'LineWidth', 2,'DisplayName',strcat('MG ',string(specimens(m))))
        hold on;
    end
    legend('Interpreter','none','Location','southeast')
    title(['By Lab Slices for Angle ',num2str(tvals(p))])
    xlabel('Moment (Nm)')
    ylabel('Resultant Rotation (deg)')
    cd ..
    saveas(gcf, [num2str(tvals(p)),'_Comparison_AMSurrogate.png']);
end