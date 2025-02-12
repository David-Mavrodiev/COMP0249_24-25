classdef KalmanFilter < ebe.localization.LocalizationSystem

    properties(Access = protected)

        % Kalman filter prediction
        xPred;
        PPred;

        % Kalman filter estimate
        xEst;
        PEst;

        % The linear system used to predict the state and the observation
        systemModel;

        % The map
        scenario

        % Store of the mean and covariance values
        timeStore;
        xStore;
        PStore;

    end

    methods(Access = public)

        function obj = KalmanFilter(config)

            % Call base class
            obj@ebe.localization.LocalizationSystem(config);

            % Set up the discrete time system for prediction
            obj.systemModel = l1.pointbot.SystemModel(config);

            % Set up the event handlers
            obj.registerEventHandler('init', @obj.handleInitializationEvent);
            obj.registerEventHandler('null_obs', @obj.handleNoObservation);
            obj.registerEventHandler('heartbeat', @obj.handleNoObservation);
            obj.registerEventHandler('gps', @obj.handleGPSObservationEvent);
            obj.registerEventHandler('bearing', @obj.handleBearingObservationEvent);

            % Set the name
            obj.setName('KalmanFilter');
        end

        function success = start(obj)
            start@ebe.core.EventBasedEstimator(obj);
            obj.timeStore = [];
            obj.xStore = zeros(4, 0);

            % Get the map data
            if (isfield(obj.config, 'scenario'))
                obj.scenario = obj.config.scenario;
            end

            success = true;
        end

        function [T, X, PX] = estimateHistory(obj)
            T = obj.timeStore;
            X = obj.xStore;
            PX = obj.PStore;
        end

        function [x, P] = computeXP(obj)
            x = obj.xEst;
            P = obj.PEst;
        end

    end

    methods(Access = protected)

        function success = handleNoPrediction(obj)
            obj.xPred = obj.xEst;
            obj.PPred = obj.PEst;
            success = true;
        end

        function success = handleNoObservation(obj, event)
            assert(obj.stepNumber == event.eventGeneratorStepNumber)

            fprintf('handleNoObservation(%f): %s\n', obj.currentTime, event.type)

            obj.xEst = obj.xPred;
            obj.PEst = obj.PPred;
            success = true;
        end

        function success = handlePredictForwards(obj, dT)

            %fprintf('handlePredictForwards(%f): dT=%f\n', obj.currentTime, dT)

            [obj.xPred, F, Q] = obj.systemModel.predictState(obj.xEst, dT);

            obj.PPred = F * obj.PEst * F' + Q;

            success = true;
        end

        function success = handleInitializationEvent(obj, event)
            assert(obj.stepNumber == event.eventGeneratorStepNumber)

            %fprintf('handleInitializationEvent(%f)\n', obj.currentTime)

            obj.xEst = event.data;
            obj.PEst = event.covariance;
            obj.initialized = true;
            success = true;
        end

        function success = handleGPSObservationEvent(obj, event)
            assert(obj.stepNumber == event.eventGeneratorStepNumber)

            fprintf('handleGPSObservationEvent(%f): complete implementation\n', obj.currentTime)

            % 1. Extract the measurement z and measurement covariance R
            z = event.data;      % e.g., [GPS_x; GPS_y] from the simulator
            R = event.covariance; 

            [zPred, H, R] = obj.systemModel.predictGPSObservation(obj.xPred);

            % Activity 4: Complete the implementation here.
            % The predicted values are in obj.xPred and obj.PPred
            % The update will put revised values in obj.xEst and
            % obj.PEst
            % 3. Innovation (residual)
            v = z - zPred;     % difference between actual measurement and predicted
        
            % 4. Innovation covariance
            S = H * obj.PPred * H' + R; 
        
            % 5. Kalman Gain
            K = obj.PPred * H' / S;
        
            % 6. State Update
            obj.xEst = obj.xPred + K * v;
        
            % 7. Covariance Update
            I = eye(size(obj.xPred,1));
            obj.PEst = (I - K * H) * obj.PPred;

            success = true;

        end

        function success = handleBearingObservationEvent(obj, event)
            assert(obj.stepNumber == event.eventGeneratorStepNumber)

            fprintf('handleBearingObservationEvent(%f): complete implementation\n', obj.currentTime)

            x = obj.xPred;
            P = obj.PPred;

            % Activity 4: Complete the implementation here.
            % The predicted values are in obj.xPred and obj.PPred
            % The update will put revised values in obj.xEst and
            % obj.PEst.  Since there are multiple landmarks, you could
            % either update them multiple times, or do a single large
            % update.

            % Extract array of bearing measurements (z) and sensor IDs from the event
            zArray    = event.data;    % array of measured bearings
            sensorIDs = event.info;    % list of sensor indices that see the robot

            % Predict each measurement
            for s = 1 : numel(event.info)
                sensor = obj.scenario.sensors.bearing.sensors(event.info(s));
                [zPred, H, R] = obj.systemModel.predictBearingObservation(x, sensor.position, sensor.orientation);
                
                % Actual bearing measurement from the event data
                zMeas = zArray(i);          % single scalar bearing measurement
                v    = zMeas - zPred;       % innovation (residual)
                
                % Innovation covariance
                S = H * P * H' + R;
                
                % Kalman gain
                K = P * H' / S;   % For scalar S, this is just a double
               
                % State update
                x = x + K * v;
                
                % Covariance update
                I = eye(size(P));
                P = (I - K * H) * P;
            end

            obj.xEst = x;
            obj.PEst = P;

            success = true;
        end

        function storeStepResults(obj)
            % Store the estimate for the future
            obj.timeStore(:, obj.stepNumber + 1) = obj.currentTime;
            obj.xStore(:, obj.stepNumber + 1) = obj.xEst;
            obj.PStore(:, obj.stepNumber + 1) = diag(obj.PEst);

        end
    end
end
