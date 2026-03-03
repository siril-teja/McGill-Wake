% without sawbones
%cd('C:\Users\emmac\Documents\arcmap_cli_v1_0_0rc2\example_datasets\McGill_WF_SPM')
% with sawbones
cd('C:\Users\emmac\Documents\SBES\Brown Lab\McGill\Data from Testing\McGill\McGill-Wakeforest Testing\SPM Prep')
tvals=linspace(0,165,(165/15)+1);
styles={'-','--',':',"-."};
specs = {'Surrogate1', 'Surrogate2', 'Surrogate3', 'Sawbones'};
hysteresis_areas={};
for p=1:length(tvals)
    hysteresis_areas{p,1}=tvals(p);
    h_col=2;
    figure;
    hold on;
    % Wake Forest
    cd(['WF_',num2str(tvals(p))])
    WF_list = dir('*.csv')
    for w=1:length(WF_list)
        WF=readmatrix(WF_list(w).name);
        plot(WF(:,1),WF(:,2),'Color',[140 109 44]./255,'LineStyle',string(styles(w)),'LineWidth', 2,'DisplayName',strcat('WF ',string(specs(w))))
        hold on;
        hysteresis_areas{p,h_col}=abs(trapz(WF(:,1),WF(:,2)));
        h_col=h_col+1;
    end
  
    % McGill
    cd ..
    cd(['MG_',num2str(tvals(p))])
    MG_list = dir('*.csv')
    for m=1:length(MG_list)
        MG=readmatrix(MG_list(m).name);
        plot(MG(:,1),MG(:,2),'Color',[248 32 33]./255,'LineStyle',string(styles(m)),'LineWidth', 2,'DisplayName',strcat('MG ',string(specs(m))))
        hysteresis_areas{p,h_col}=abs(trapz(MG(:,1),MG(:,2)));
        hold on;
        h_col=h_col+1;
    end
    legend('Interpreter','none','Location','southeast')
    title(['By Lab Slices for Angle ',num2str(tvals(p))])
    xlabel('Moment (Nm)')
    ylabel('Resultant Rotation (deg)')
    cd ..
    saveas(gcf, [num2str(tvals(p)),'_Comparison_AMSurrogate.png']);
end

writecell(hysteresis_areas, fullfile(save_folder,'hysteresis.csv'));

CM=[248 32 33]./255;
CW=[140 109 44]./255;
hyst=figure;
subplot(1,3,1)
h1=bar(cell2mat(hysteresis_areas(:,1)),[cell2mat(hysteresis_areas(:,2)),cell2mat(hysteresis_areas(:,5))])
h1(1).FaceColor = CW; h1(2).FaceColor = CM;
title(string(specs(1)))
xlabel('Primary Slice Angle (deg)')
ylabel('Hysteresis Area')
subplot(1,3,2)
h2=bar(cell2mat(hysteresis_areas(:,1)),[cell2mat(hysteresis_areas(:,3)),cell2mat(hysteresis_areas(:,6))])
h2(1).FaceColor = CW; h2(2).FaceColor = CM;
title(string(specs(2)))
xlabel('Primary Slice Angle (deg)')
ylabel('Hysteresis Area')
subplot(1,3,3)
h3=bar(cell2mat(hysteresis_areas(:,1)),[cell2mat(hysteresis_areas(:,4)),cell2mat(hysteresis_areas(:,7))])
h3(1).FaceColor = CW; h3(2).FaceColor = CM;
title(string(specs(3)))
xlabel('Primary Slice Angle (deg)')
ylabel('Hysteresis Area')
sgtitle('McGill Specimens Hysteresis Area')

figure;
hold on;
for h=2:size(hysteresis_areas,2)
    scatter(cell2mat(hysteresis_areas(:,1)),cell2mat(hysteresis_areas(:,h)),'DisplayName',string(specs(floor(h./2))))
end
legend show
