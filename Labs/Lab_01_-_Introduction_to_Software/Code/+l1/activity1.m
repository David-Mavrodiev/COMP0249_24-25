% This script shows how to set up the individual pieces of the code and
% start running them

import ebe.core.*;
import ebe.graphics.*;
import l1.pointbot.*;

% Find, load and parse the configuration file
config = ebe.utils.readJSONFile('config/activity1.json');

% Set up the simulator and start it
simulator = Simulator(config);
simulator.start();

% Set up the figure in which we draw everything
fig = FigureManager.getFigure("Simulator Output");
clf
hold on
axis([-80 80 -80 80])
axis square

% Set up the view which show the output of the simulator and start it
simulatorViewer = ebe.graphics.ViewManager(config);
simulatorViewer.addView(SimulatorView(config, simulator));
simulatorViewer.start();

% This is the main loop - while the simulator says we should keep going, we
% step the simulator, extract the events which were generated, and
% visualize them.
while (simulator.keepRunning()  == true)
    simulator.step();
    events = simulator.events();
    simulatorViewer.visualize(events);
    drawnow
end

% Retrieve the stored histories
[timeHistory, xTrueHistory] = simulator.history();

% Find the smallest and largest times
minTime = min(timeHistory);
maxTime = max(timeHistory);

% (Optional) Find the smallest and largest entries in the state history
minStateValue = min(xTrueHistory(:));  % Flatten xTrueHistory into a vector
maxStateValue = max(xTrueHistory(:));

% Display results
disp('Minimum time:'), disp(minTime)
disp('Maximum time:'), disp(maxTime)
disp('Minimum state value:'), disp(minStateValue)
disp('Maximum state value:'), disp(maxStateValue)
