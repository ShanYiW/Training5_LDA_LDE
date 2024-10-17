% 5折交叉验证
clear;
load("Yale_32.mat");
DATA = fea'; clear fea;
[D,N] = size(DATA);
rand('seed', 6); % 
cv5 = randperm(N)';
fold = 5; % 5-fold cross validation
Ntest = floor(N/fold);
Ntrain = N - Ntest;
%% 遍历(d1, d2), 固定(k, t).
for k=24
t=3e5;
D1=32; lb_d1=2; len_d1=D1-lb_d1+1;
D2=32; lb_d2=2; len_d2=D2-lb_d2+1;
Acc_cv5 = zeros([len_d1, len_d2, fold]);
for f=1:fold
    is_test = false([N,1]);
    is_test((f-1)*Ntest+1:f*Ntest) = true;
    is_train = ~is_test;
    
    testset = DATA(:, cv5(is_test)); % D*Ntest
    gndtest = gnd(cv5(is_test)); % Ntest*1
    trainset = DATA(:, cv5(is_train)); % D*Ntrain
    gndtrain = gnd(cv5(is_train)); % Ntrain*1
    
    trainset3 = zeros([D1,D2,Ntrain]);
    testset3  = zeros([D1,D2, Ntest]);
    for j=1:Ntrain
        trainset3(:,:,j) = reshape(trainset(:,j), [D1,D2]);
    end
    for j=1:Ntest
        testset3(:,:,j) = reshape(testset(:,j), [D1,D2]);
    end
    
    [L,R] = d2LPP(trainset, D1,D2, k, t); % L:D1*D1  R:D2*D2
    for d1=lb_d1:D1
        for d2=lb_d2:D2
            Y_train = zeros([d1*d2, Ntrain]);
            Y_test = zeros([d1*d2, Ntest]);
            for j=1:Ntrain
                yj = L(:,1:d1)'*trainset3(:,:,j)*R(:,1:d2); % D1*D2
                Y_train(:,j) = yj(:);
            end
            for j=1:Ntest
                yj = L(:,1:d1)'*testset3(:,:,j)*R(:,1:d2); % D1*D2
                Y_test(:,j) = yj(:);
            end
            acc = 0;
            for j=1:Ntest
                y = Y_test(:,j); % d*1
                dist = sum((repmat(y,[1,N-Ntest]) - Y_train).^2, 1);
                [~,idx] = sort(dist); % 距离 升序排
                pred = gndtrain(idx(1)); % 最近邻的类别 = j号测试样本的类别
                acc = acc + (pred==gndtest(j));
            end
            acc = acc/Ntest; % 
            Acc_cv5(d1-lb_d1+1, d2-lb_d2+1, f) = acc;
        end
    end
end
Acc_avg = mean(Acc_cv5, 3); % len_d1*len_d2
maxAcc = Acc_avg(1,1); maxidx = 1;
for j=2:len_d1*len_d2
    if Acc_avg(j)>maxAcc
        maxAcc = Acc_avg(j);
        maxidx = j;
    end
end
fprintf('Max: %f %d\n', maxAcc, maxidx);
figure('Name',['k',num2str(k), '_t',num2str(t)]);
bar_3 = bar3(Acc_avg);
for k=1:length(bar_3)
    bar_3(k).CData = bar_3(k).ZData; % 颜色与Z取值成正比
    bar_3(k).FaceColor = 'interp';
end
zlim([0.5 ,0.75]);
set(gca,'XGrid', 'off', 'YGrid', 'off','ZGrid', 'on')
xlabel('$d_2$', 'Interpreter', 'latex', 'Fontsize', 14);
ylabel('$d_1$', 'Interpreter', 'latex', 'Fontsize', 14);
zlabel('$Accuracy$', 'Interpreter', 'latex', 'Fontsize', 14);
view([-90, 1]); % 0度:延第二维度(↓)的反方向(↑) 正视第一维度(→)
end