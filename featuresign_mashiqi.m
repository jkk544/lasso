function beta = featuresign_mashiqi(X, y, lambda, standardize)
%{
% Feature-Sign algorithm.
% Author: Shiqi Ma (mashiqi01@gmail.com, http://mashiqi.github.io/)
% Date: 1/10/2015
% Version: 2.0
% 
% This code solves the following problem:
%            argmin_(beta) 0.5*||y - X*beta||_2 + lambda*||beta||_1
% 
% Parameter instruction:
% input:
% X: samples of predictors. Each column of X is a predictor, and each row
% is a data sample.
% y: the response.
% lambda: the coefficient of the norm-one term.
% standardize: the indicator. If standardize == 1, every column in X and y
% will be standardized to mean zero and standard deviation 1. And if its
% value is 0, then standardization process will not be executed.
% standardize == 0 as default.
%
% output:
% beta: weight vector.
%
% reference: 
% [1] Lee, Honglak, et al. "Efficient sparse coding algorithms." Advances
      in neural information processing systems. 2006. 
%}

if nargin < 4
    standardize = 0;
end
if standardize == 1
    n = size(X,1); % number of samples
    X = bsxfun(@minus,X,mean(X,1));
    X = bsxfun(@rdivide,X,sqrt(sum(X.^2,1)));
    y = bsxfun(@minus,y,mean(y,1));
end

if lambda == 0
    lambda = 1e-17; % �ݶȿ�����Զ�����ܴﵽ����0�����Էſ�һ��
end

p = size(X,2); % number of predictors
activeSet = false(p,1);
beta = zeros(p,1);
theta = zeros(p,1);
XTX = X'*X;
optimality_a = false;
optimality_b = false;

% Step 1 :corresponding to the "Algorithm 1" in "Efficient sparse coding
% algorithm"
grad = XTX*beta-X'*y; %�ݶ�����

% Step 2 :ͬ��
    [~,currentIndex] = max( abs(grad).*(~activeSet) );
    cnt = 2;
while ~optimality_b
    cnt = cnt + 1;
    if grad(currentIndex) > lambda
        theta(currentIndex) = -1;
        activeSet(currentIndex) = true;
    elseif grad(currentIndex) < -lambda
        theta(currentIndex) = 1;
        activeSet(currentIndex) = true;
    else
        return; % ˵���Ѿ��ﵽ��Сֵ
    end

    % Step 3 :ͬ��
    while ~optimality_a
        betaHat = zeros(p,1);
        betaUpdate = zeros(p,1);
        betaHat(activeSet) = beta(activeSet);
        betaUpdate(activeSet) = XTX(activeSet,activeSet) \ ( X(:,activeSet)'*y - lambda*theta(activeSet) );
        
        % Step 4 :ͬ��
        temp1 = betaUpdate ./ betaHat; % temp1������Ϊ���ж�beta(activeSet)����ǰ������Щ�����ı���������
        temp1(isnan(temp1))=0; % ������temp1�е���NaN��Ԫ����Ϊ0ֵ
        temp1(isinf(temp1))=0; % ������temp1�е�������Inf��Ԫ����Ϊ0ֵ
        [scale,j] = min( temp1 );
        if scale >= 0 % ˵��û��active��ϵ������θ��¹����иı�������
            beta(activeSet) = betaUpdate(activeSet); % ������õľֲ����Žⷵ�����beta
            grad = XTX*beta-X'*y; % �����ݶ�����
            [grad_value_abs,currentIndex] = max( abs(grad).*(~activeSet) );
            optimality_a = true;
            if ~isempty(grad_value_abs) && (grad_value_abs <= lambda) % abs(grad_value) <= lambda
                                                               % ��act_idx0Ϊ�ռ�ʱ����ζ��beta�����з������ڶ���Ϊ��
                                                               % ��ʹgrad =0,���Դ�ʱ��beta�������Ž��ˣ�Ӧ������ѭ���ˡ�
                optimality_b = true;
            else
                optimality_a = false;
                optimality_b = false;
                break; % ����optimality_aѭ��������ѡ���µ����������step2�ٿ�ʼ
            end
        else
            % ������s��s_new�������������ȸı���ŵķ������±�
            betaHat = betaHat + ( betaUpdate - betaHat )/(1-scale);
            betaHat(j) = 0; % ȷ����һ��������ķ���һ��ҪΪ��
            beta = betaHat; % ������õľֲ����Žⷵ�����beta
            theta(j) = 0; % ���˹����ķ����ķ�������
            activeSet(j) = false; % ��active set������˷���
            optimality_a = false;
        end
    end % optimality_a
end % optimality_b
return;