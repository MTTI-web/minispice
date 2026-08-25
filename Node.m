classdef Node
  properties
    Name
    AdjElements
  end

  methods
    % Constructor
    function obj = Node(Name, AdjElements)
      if nargin < 1
        Name = "";
      end

      if nargin < 2
        AdjElements = {};
      end

      obj.Name = Name;
      obj.AdjElements = AdjElements;
    end

    % Add one adjacent element
    function obj = addElement(obj, element)
      obj.AdjElements{end + 1} = element;
    end

    % Return the node name
    function name = getName(obj)
      name = obj.Name;
    end
  end
end