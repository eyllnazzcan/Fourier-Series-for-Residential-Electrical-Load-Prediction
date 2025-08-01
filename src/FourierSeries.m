clear
close all

dataset = readtable("Load1r.xlsx"); % load dataset
days = [1, 92, 183, 274]; % the days that should be analyzed

T = 24; % period for Fourier series (24 hours in a day)
maxHarmonics = 20; % maximum number of harmonics to try
kfold = 5; % number of folds for cross-validation

for i = 1:length(days)
    % filters data for every day that should be analyzed
    day = dataset(dataset.day == days(i), ["hour", "load_MWh_"]);
    x = day.hour; % independent variable
    y = day.load_MWh_; % dependent variable

    n = height(day); % number of samples
    partition = cvpartition(n, "KFold", kfold);
    mse = zeros(maxHarmonics, 1); % to store MSE for each harmonic

    % determines the optimal number of harmonics using k-fold
    % cross-validation and implements the fourier series.
    % to evaluate the performance of the model, it calculates both the
    % error of cross validation (test MSE) and error of all data
    % (final MSE)

    for k = 1:maxHarmonics
        foldErrors = zeros(kfold, 1); % to store errors for each fold

        for fold = 1:kfold
            % split data into training and testing sets
            trainIndex = training(partition, fold);
            testIndex = test(partition, fold);

            trainX = x(trainIndex);
            trainY = y(trainIndex);
            testX = x(testIndex);
            testY = y(testIndex);

            % fit Fourier series on training data
            p = fourfit(trainX, trainY, T, k);

            % make predictions on test data
            yhat = fourval(p, T, testX);

            % calculate MSE for the fold
            foldErrors(fold) = mean((testY - yhat).^2);
        end

        % average MSE across all folds for this number of harmonics
        mse(k) = mean(foldErrors);
    end

    % plot MSE vs number of harmonics
    figure("Name", "MSE vs Harmonics for Day " + days(i))
    plot(1:maxHarmonics, mse, '-o', 'LineWidth', 1.5)
    xlabel("Number of Harmonics")
    ylabel("Mean Squared Error (MSE)")
    title("MSE vs. Number of Harmonics (Day " + days(i) + ")")
    grid on


    % find optimal number of harmonics based on minimum MSE
    [minMSE, optimalHarmonics] = min(mse);

    % find optimal number of harmonics based on minimum MSE
    [~, optimalHarmonics] = min(mse);

    % fit the Fourier series with the optimal number of harmonics
    bestParams = fourfit(x, y, T, optimalHarmonics);
    bestFit = fourval(bestParams, T, x);

    % computes final MSE on the entire dataset
    finalMSE = mean((y - fourval(bestParams, T, x)).^2);

    % display results
    disp("----------------------------------------")
    disp("Day: " + days(i))
    disp("Optimal Harmonics: " + optimalHarmonics)
    disp("K-Fold Cross-validated Test MSE: " + minMSE)
    disp("MSE for all data: " + finalMSE)

    % plot results
    figure("Name", "Day " + days(i))
    
    subplot(2, 2, 1)
    plot(x, y, "*") % original data
    hold on
    plot(x, bestFit, "r") % fourier fit
    xlabel("Time [h]")
    ylabel("Load [MWh]")
    title("Day " + days(i))
    legend("Data", "Fourier Fit")
    hold off

    % compute residuals and normalized residuals
    residuals = y - bestFit;
    sigmahat = sqrt(sum(residuals.^2) / (length(y) - length(bestParams)));
    resnorm = residuals / sigmahat; % normalized residuals

    % plots normalized residuals
    subplot(2, 2, 3)
    plot(day.hour, resnorm, 'o-', 'DisplayName', 'Normalized Residuals');
    hold on;
    yline(1, '--r', 'LineWidth', 1.5, 'DisplayName', '+1 Std. Deviation');
    yline(-1, '--r', 'LineWidth', 1.5, 'DisplayName', '-1 Std. Deviation');
    ylabel("Normalized Residuals")
    xlabel("Time [h]")
    legend show;
    grid on
    title("Normalized Residuals of Fourier Series")

    % plot histogram of residuals
    subplot(2, 2, 4)
    histogram(residuals, 10)
    title("Residuals Distribution")
    xlabel("Residual")
    ylabel("Frequency")

    % F-test to evaluate the significance of the model
    subplot(2, 2, 2)
    fstat = HypotesysFtest(y, bestFit, length(y), length(bestParams));
    pvalue = 1 - fcdf(fstat, length(bestParams), length(y) - length(bestParams) - 1);
    txt = sprintf("H0: Fourier series terms are not significant\nDay %d\nF = %.2f\n", days(i), fstat);
    if pvalue < 0.05
        txt = txt + "Reject H0: Fourier model is significant";
    else
        txt = txt + "Accept H0: Fourier model is not significant";
    end
    text(0.5, 0.5, txt, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle')
    axis off
end
