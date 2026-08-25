classdef Element
  properties
    Name string
    Type Device
    Value double
    Nodes {Node, Node}
    DependsOn % (a,b) or (element)
  end

  methods
    function obj = ClassName(inputArg1)
      obj.Property1 = inputArg1^2;
      disp(obj.Property1);

    end
  end
end