% This script shows how to set up the individual pieces of the code and
% start running them

import ebe.core.*;
import ebe.graphics.*;
import l1.pointbot.*;

% Find, load and parse the configuration file
config = ebe.utils.readJSONFile('config/activity2.json');

% Set up the simulator and start it
simulator = Simulator(config);
simulator.start();

% Set up the figure in which we draw everything
fig = FigureManager.getFigure("Simulator Output");
clf
hold on
axis([-10 10 -10 10])
axis square

% Set up the view which show the output of the simulator and start it
simulatorViewer = ebe.graphics.ViewManager(config);
simulatorViewer.addView(SimulatorView(config, simulator));
simulatorViewer.start();

% This is the main loop - while the simulator says we should keep going, we
% step the simulator, extract the events which were generated, and
% visualize them.
% main loop - while the simulator says we should keep going, step it
% and process events
while simulator.keepRunning()
    simulator.step();

    events = simulator.events();
    if ~isempty(events)
        disp('=== New Events This Step ===');
        for i = 1:numel(events)
            e = events{i}; % curly braces if events is a cell array

            fprintf('  Event %d:\n', i);
            fprintf('    Time: %.3f\n', e.time);
            fprintf('    Type: %s\n', e.type);

            if isprop(e, 'eventGeneratorStepNumber')
                fprintf('    Step #: %d\n', e.eventGeneratorStepNumber);
            end

            if isprop(e, 'data') && ~isempty(e.data)
                fprintf('    Data: %s\n', mat2str(e.data));
            end

            % No references to e.args
        end
        disp('----------------------------------')
    end

    simulatorViewer.visualize(events);
    drawnow;
end


