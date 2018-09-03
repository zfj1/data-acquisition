classdef FlashingSpots < sa_labs.protocols.StageProtocol & sa_labs.common.ProtocolLogger
    
        
    properties
        %times in ms
        preTime = 500                   % Spot leading duration (ms)
        stimTime = 16.7 
        tailTime = 500                  % Spot trailing duration (ms)
        spotSize = 200;                 % spot diameter (um)
        numberOfRepetions = 30;         % 
        randomOrdering = false;         % ramdom presentation order
        temporal = true;
        
    end
    
    properties (Hidden)
        version = 1
        stimTimeInit = 16.7                 % initial spot duration (ms)
        numberOfCombinations = 5;        % 
        order                           % current presetnation order
        combIdx
        durations
        duration                        % current duration
        intensities
        intensity                       % current intensity
        spotSizes
        size                            % current size
        responsePlotMode = 'cartesian';
        responsePlotSplitParameter = 'combIdx';
    end
    
    properties (Hidden, Dependent)
        totalNumEpochs
    end
    
    methods
        
        function prepareRun(obj)
            obj.logPrepareRun();
            prepareRun@sa_labs.protocols.StageProtocol(obj);
            
            % Generate points on a grid
            if obj.temporal
                obj.intensities = logspace(log10(0.0625), log10(1), 5);
                obj.spotSizes = obj.spotSize * ones(1, 5);
                obj.durations = obj.stimTimeInit * 2.^(4:-1:0);
            else
                obj.intensities = [1, 0.61, 0.5, 0.47, 0.46];
                obj.spotSizes = 200:100:600;
                obj.durations = obj.stimTimeInit*ones(1, 5);
            end
            % Start with the default order
            obj.order = 1:obj.numberOfCombinations;
            
        end
            
        function prepareEpoch(obj, epoch)
            obj.logPrepareEpoch(epoch);
            
            % Randomize the order if this is a new cycle
            index = mod(obj.numEpochsPrepared, obj.numberOfCombinations) + 1;
            if index == 1 && obj.randomOrdering
                obj.order = obj.order(randperm(obj.numberOfCombinations)); 
            end
            
            % Get the current position and intensity
            obj.combIdx = obj.order(index);
            obj.stimTime = obj.durations(obj.combIdx);
            obj.duration = obj.durations(obj.combIdx);
            obj.intensity = obj.intensities(obj.combIdx);
            obj.size = obj.spotSizes(obj.combIdx);
            
            epoch.addParameter('combIdx', obj.combIdx);
            epoch.addParameter('duration', obj.duration);
            epoch.addParameter('intensity', obj.intensity);
            epoch.addParameter('size', obj.size);
            
            % Call the base method.
            prepareEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
                        
        end     
      
        function p = createPresentation(obj)
            p = stage.core.Presentation((obj.preTime + obj.stimTime + obj.tailTime) * 1e-3);

            spot = stage.builtin.stimuli.Ellipse();
            spot.radiusX = round(obj.um2pix(obj.size / 2));
            spot.radiusY = spot.radiusX;
            spot.color = obj.intensity;
            canvasSize = obj.rig.getDevice('Stage').getCanvasSize();
            spot.position = canvasSize / 2;
            spot.opacity = 1;
            p.addStimulus(spot);
            
            obj.setOnDuringStimController(p, spot);
            
            % shared code for multi-pattern objects
            obj.setColorController(p, spot);

        end
        
        function totalNumEpochs = get.totalNumEpochs(obj)
            totalNumEpochs = obj.numberOfRepetions * obj.numberOfCombinations;
        end
        
        function completeEpoch(obj, epoch)
            completeEpoch@sa_labs.protocols.StageProtocol(obj, epoch);
            obj.logCompleteEpoch(epoch);
        end
        
        function completeRun(obj)
            completeRun@sa_labs.protocols.StageProtocol(obj);
            obj.logCompleteRun();
        end
    end
end

