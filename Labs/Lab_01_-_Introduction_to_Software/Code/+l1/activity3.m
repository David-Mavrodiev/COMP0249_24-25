% This script shows how to set up the individual pieces of the code and
% start running them

import ebe.core.*;
import ebe.graphics.*;
import l1.pointbot.*;

% Find, load and parse the configuration file
config = ebe.utils.readJSONFile('config/activity3.json');

% Set up the simulator and start it
simulator = Simulator(config);
simulator.start();

% Create the Kalman filter and start it
kf = KalmanFilter(config);
kf.start();

% Set up the figure in which we draw everything
fig = FigureManager.getFigure("Simulator Output");
clf
hold on
axis([-20 20 -20 20])
axis square

% Set up the view which show the output of the simulator
simulatorViewer = ebe.graphics.ViewManager(config);
simulatorViewer.addView(SimulatorView(config, simulator));

% Register a viewer to show the Kalman filter results
simulatorViewer.addView(ebe.graphics.MeanCovarianceView(config, kf, [1 3]));

simulatorViewer.start();

% This is the main loop - while the simulator says we should keep going, we
% step the simulator, extract the events which were generated, and
% visualize them.
while (simulator.keepRunning()  == true)
    simulator.step();
    events = simulator.events();
    kf.processEvents(events);
    simulatorViewer.visualize(events);
    drawnow
end

% Retrieve the time history, state, and diagonal of covariance
[T, X, PX] = kf.estimateHistory();

% X is typically a 4 x N matrix, where N is the number of time steps
% PX is typically a 4 x N matrix, holding diag(PEst) at each step

figure('Name','Kalman Filter Estimate History','NumberTitle','off');

% ----------------------------
% Plot X(1) and X(3), i.e., x and y positions over time
subplot(2,1,1);
plot(T, X(1,:), 'r-o','DisplayName','x-position');
hold on;
plot(T, X(3,:), 'b-o','DisplayName','y-position');
grid on;
xlabel('Time (s)');
ylabel('Position (m)');
legend('Location','best');
title('Estimated Position Over Time');

% ----------------------------
% Plot PX(1) and PX(3), i.e., variance in x and y
subplot(2,1,2);
plot(T, PX(1,:), 'r-o','DisplayName','Var(x)');
hold on;
plot(T, PX(3,:), 'b-o','DisplayName','Var(y)');
grid on;
xlabel('Time (s)');
ylabel('Variance');
legend('Location','best');
title('Covariance Diagonal Over Time');
