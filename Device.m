classdef Device
    enumeration
        Resistor
        Capacitor
        Inductor

        VoltageSource
        CurrentSource

        VCVS  % Voltage-Controlled Voltage Source
        CCCS  % Current-Controlled Current Source
        VCCS  % Voltage-Controlled Current Source
        CCVS  % Current-Controlled Voltage Source
    end
end