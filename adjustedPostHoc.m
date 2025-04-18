function results = adjustedPostHoc(Y, Group, Covariate, method)
    % adjustedPostHoc performs ANCOVA and pairwise post hoc comparisons
    % adjusted for a covariate using LSD or Bonferroni correction.
    %
    % method: 'lsd' (default) or 'bonferroni'
    %
    % returns: table with columns:
    %   Group1, Group2, Difference, tValue, pValue, Significant

    if nargin < 4
        method = 'lsd';
    end

    % Ensure Group is categorical
    if ~iscategorical(Group)
        Group = categorical(Group);
    end

    % Create table and fit ANCOVA model
    tbl = table(Y, Group, Covariate);
    mdl = fitlm(tbl, 'Y ~ Group + Covariate');

    % Predict adjusted means at the mean covariate
    meanCov = mean(Covariate);
    groupLevels = categories(Group);
    newData = table(categorical(groupLevels), repmat(meanCov, numel(groupLevels),1), ...
        'VariableNames', {'Group', 'Covariate'});

    [adjMeans, adjCI] = predict(mdl, newData);

    % Approximate SE from CI (assuming 95%)
    SE = (adjCI(:,2) - adjCI(:,1)) / (2 * 1.96);
    df = mdl.DFE;

    % Display adjusted means
    fprintf('\nAdjusted group means (estimated marginal means):\n');
    disp(table(groupLevels, adjMeans, SE, ...
        'VariableNames', {'Group', 'AdjMean', 'SE'}));

    % Determine comparison method
    alpha = 0.05;
    nGroups = numel(groupLevels);
    nComparisons = nchoosek(nGroups, 2);

    if strcmpi(method, 'bonferroni')
        alpha_adj = alpha / nComparisons;
        methodLabel = sprintf('Bonferroni-adjusted (alpha = %.4f)', alpha_adj);
    else
        alpha_adj = alpha;
        methodLabel = sprintf('LSD (alpha = %.2f)', alpha);
    end

    tcrit = tinv(1 - alpha_adj/2, df);

    % Pairwise comparisons
    fprintf('\nPost Hoc Comparisons using %s:\n', methodLabel);
    fprintf('%-10s vs %-10s | Diff     | t-value  | p-value  | Significant\n', 'Group 1', 'Group 2');
    fprintf('------------------------------------------------------------------\n');

    % Initialize result containers
    results = table([], [], [], [], [], [], ...
        'VariableNames', {'Group1', 'Group2', 'Difference', 'tValue', 'pValue', 'Significant'});

    for i = 1:nGroups-1
        for j = i+1:nGroups
            diff = adjMeans(i) - adjMeans(j);
            pooledSE = sqrt(SE(i)^2 + SE(j)^2);
            tval = abs(diff) / pooledSE;
            p = 2 * (1 - tcdf(tval, df));
            sig = p < alpha_adj;

            fprintf('%-10s vs %-10s | %+8.4f | %8.3f | %8.4f | %s\n', ...
                groupLevels{i}, groupLevels{j}, diff, tval, p, ternary(sig, 'YES', 'NO'));

            % Add to results table
            results = [results; {
                groupLevels{i}, groupLevels{j}, diff, tval, p, sig
            }];
        end
    end
end

function out = ternary(cond, valTrue, valFalse)
    if cond
        out = valTrue;
    else
        out = valFalse;
    end
end
