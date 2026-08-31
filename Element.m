classdef Element < handle

  properties
    Name string
    Type Device
    Value double
    VS_ID
    Nodes
    DependsOn
  end

  methods

    function obj = Element(words)
      name = words{1};
      node1 = words{2};
      node2 = words{3};
      obj.Name = string(name);
      obj.Nodes = {node1, node2};
      obj.VS_ID = 0;
      switch upper(name(1))
        case "V"
          obj.Type = Device.VoltageSource;
          obj.Value = valParse(words{end});
        case "I"
          obj.Type = Device.CurrentSource;
          obj.Value = valParse(words{end});
        case "R"
          obj.Type = Device.Resistor;
          obj.Value = valParse(words{4});
        case "L"
          obj.Type = Device.Inductor;
          obj.Value = valParse(words{4});
        case "C"
          obj.Type = Device.Capacitor;
          obj.Value = valParse(words{4});
        case "E"
          obj.Type = Device.VCVS;
          obj.DependsOn = {words{4},words{5}};
          obj.Value = valParse(words{6});
        case "F"
          obj.Type = Device.CCCS;
          obj.DependsOn = words{4};
          obj.Value = valParse(words{5});
        case "G"
          obj.Type = Device.VCCS;
          obj.DependsOn = {words{4},words{5}};
          obj.Value = valParse(words{6});
        case "H"
          obj.Type = Device.CCVS;
          obj.DependsOn = words{4};
          obj.Value = valParse(words{5});
        otherwise
          error("Unknown device type: %s", obj.Name);

      end
    end

  end
end