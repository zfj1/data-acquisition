classdef SchwartzLab_Rig_Base < symphonyui.core.descriptions.RigDescription
    
    methods
        
        function initializeRig(obj)
            
            import symphonyui.builtin.daqs.*;
            import symphonyui.builtin.devices.*;
            import symphonyui.core.*;
            
            if obj.testMode
                daq = HekaSimulationDaqController();
            else
                daq = HekaDaqController(HekaDeviceType.USB18);
            end
            
            obj.daqController = daq;
            
            for i = 1:obj.numberOfAmplifiers
                amp = MultiClampDevice(sprintf('Amp%g', i), i).bindStream(daq.getStream(sprintf('ao%g', i-1))).bindStream(daq.getStream(sprintf('ai%g', i-1)));
                obj.addDevice(amp);
            end
            
            propertyDevice = sa_labs.devices.RigPropertyDevice(obj.rigName, obj.testMode);
            obj.addDevice(propertyDevice);

            rigProperty = sa_labs.factory.getInstance('rigProperty');
            rigProperty.rigDescription = obj;
            
            if ~obj.testMode
                oscopeTrigger = UnitConvertingDevice('Oscilloscope Trigger', symphonyui.core.Measurement.UNITLESS).bindStream(daq.getStream('doport1'));
                daq.getStream('doport1').setBitPosition(oscopeTrigger, 0);
                obj.addDevice(oscopeTrigger);
            end
            
            neutralDensityFilterWheel = sa_labs.devices.NeutralDensityFilterWheelDevice(obj.filterWheelComPort);
            neutralDensityFilterWheel.setConfigurationSetting('filterWheelNdfValues', obj.filterWheelNdfValues);
            neutralDensityFilterWheel.addResource('filterWheelAttenuationValues', obj.filterWheelAttenuationValues);
            neutralDensityFilterWheel.addResource('defaultNdfValue', obj.filterWheelDefaultValue);
            obj.addDevice(neutralDensityFilterWheel);
            
            lightCrafter = sa_labs.devices.LightCrafterDevice('colorMode', obj.projectorColorMode, 'orientation', obj.orientation);
            lightCrafter.setConfigurationSetting('micronsPerPixel', obj.micronsPerPixel);
            lightCrafter.setConfigurationSetting('angleOffset', obj.angleOffset);
            lightCrafter.setConfigurationSetting('frameTrackerPosition', obj.frameTrackerPosition);
            lightCrafter.setConfigurationSetting('frameTrackerSize', obj.frameTrackerSize);
            lightCrafter.addResource('fitBlue', obj.fitBlue);
            lightCrafter.addResource('fitGreen', obj.fitGreen);
            lightCrafter.addResource('fitUV', obj.fitUV);
            obj.addDevice(lightCrafter);
            
        end
        
        function [rstar, mstar, sstar] = convertIntensityToIsomerizations(obj, protocol)
            rstar = [];
            mstar = [];
            sstar = [];
            
            if isempty(protocol.intensity)
                return
            end
            
            filterIndex = find(obj.filterWheelNdfValues == protocol.NDF, 1);
            NDF_attenuation = obj.filterWheelAttenuationValues(filterIndex);
            
            if strcmp('standard', protocol.colorMode)
                [R, M, S] = sa_labs.util.photoIsom2(protocol.blueLED, protocol.greenLED, ...
                    protocol.colorPattern1, obj.fitBlue, obj.fitGreen);
            else
                % UV mode
                [R, M, S] = sa_labs.util.photoIsom2_triColor(protocol.blueLED, protocol.greenLED, protocol.uvLED, ...
                    protocol.colorPattern1, obj.fitBlue, obj.fitGreen, obj.fitUV);
            end
            
            rstar = round(R * protocol.intensity * NDF_attenuation / protocol.numberOfPatterns, 1);
            mstar = round(M * protocol.intensity * NDF_attenuation / protocol.numberOfPatterns, 1);
            sstar = round(S * protocol.intensity * NDF_attenuation / protocol.numberOfPatterns, 1);
        end
    end
    
end

