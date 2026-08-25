classdef Element < handle

  properties
    Name string
    Type Device
    Value double
    Nodes (1,2) Node
    DependsOn
  end

  methods

    function obj = Element(name, node1, node2, value)

      obj.Name = string(name);
      obj.Nodes = [node1, node2];
      obj.Value = valParse(value);
      % disp(name(1));
      switch upper(name(1))
        case "V"
          obj.Type = Device.VoltageSource;
        case "I"
          obj.Type = Device.CurrentSource;
        case "R"
          obj.Type = Device.Resistor;
        case "L"
          obj.Type = Device.Inductor;
        case "C"
          obj.Type = Device.Capacitor;
        case "E"
          obj.Type = Device.VCVS;
        case "F"
          obj.Type = Device.CCCS;
        case "G"
          obj.Type = Device.VCCS;
        case "H"
          obj.Type = Device.CCVS;
        otherwise
          error("Unknown device type: %s", obj.Name);

      end
    end

  end
end