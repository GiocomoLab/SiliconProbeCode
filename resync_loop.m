% loop to sync IMEC and NIDAQ board for all sessions in the paper
root = 'Z:\giocomo\export\data\Projects\RandomForage_NPandH3\ProcessedData\';
mice = ["Milan", "Pisa", "Hanover", "Boston", "Camden", "Calais", ...
    "Seattle", "Portland", "Juneau", "Quebec", "Toronto", "Vancouver"];
%     "Seoul", "Degu", "Busan", "Inchon", "Ulsan"];
sessions = {};
sessions{1} = ["0420_2", "0424_1"];
sessions{2} = ["0430_1", "0501_1", "0502_1"];
sessions{3} = ["0615_2", "0617_5"];
sessions{4} = ["0617_1", "0619_2"];
sessions{5} = ["0711_2"];
sessions{6} = ["0712_2", "0713_2"];
sessions{7} = ["1005_1", "1006_1", "1007_1", "1009_1", "1010_1"]; 
sessions{8} = ["1005_2"]; 
sessions{9} = ["1102_1", "1104_1", "1105_1", "1106_1"]; 
sessions{10} = ["1007_1", "1009_1"]; 
sessions{11} = ["1111_1", "1112_1", "1113_1", "1114_1", "1115_1", "1117_1"]; 
sessions{12} = ["1114_1", "1115_1"]; 
% sessions{13} = ["0720", "0721", "0722", "0724"]; 
% sessions{14} = ["0720", "0721", "0722", "0725"]; 
% sessions{15} = ["0730", "0731", "0801", "0802", "0803"]; 
% sessions{16} = ["0810", "0811", "0812", "0814"]; 
% sessions{17} = ["0802"];

for i = 1:length(mice)
    mouse = mice(i);
    session = sessions{i};
    for j = 1:length(session)
        if length(session)==1
            s = session;
        else
            s = session(j);
        end
        
        % check if already saved
        if isfile(strcat('F:\ilow\sync_data\', mouse, '_', s, '_data.mat'))
            continue
        end
        
        date = split(s, '_');
        date = date(1);
        main_name = strcat(mouse, '_', date, '_g0');
        data_dir = strcat(root, mouse, '\', main_name, '\');
        
        if exist(data_dir, 'dir')
            fprintf('syncing: %s, session %s...\n', mouse, s)
        elseif (mouse == 'Busan') && (s == '0803')
            main_name = strcat(mouse, '_', s, '_1_g0');
            data_dir = strcat(root, mouse, '\', main_name, '\');
            if exist(data_dir, 'dir')
                fprintf('syncing: %s, session %s...\n', mouse, s)
            else
                fprintf('main name error: %s, session %s!\n', mouse, s)
                continue
            end
        else
            main_name = strcat(mouse, '_', s, '_g0');
            data_dir = strcat(root, mouse, '\', main_name, '\');
            if exist(data_dir, 'dir')
                fprintf('syncing: %s, session %s...\n', mouse, s)
            else
                fprintf('main name error: %s, session %s!\n', mouse, s)
                continue
            end
        end
        
        sync_IMEC_NIDAQ(data_dir, main_name, mouse, s)
    end
end