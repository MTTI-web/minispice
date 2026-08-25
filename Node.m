classdef Node < handle
  properties
    Name
    Id
    AdjElements
  end

  methods
    function obj = Node(Name, AdjElements)
      obj.Id = 0;
      if nargin < 1
        Name = "";
      end

      if nargin < 2
        AdjElements = {};
      end

      obj.Name = Name;
      obj.AdjElements = AdjElements;
    end

    function obj = addElement(obj, element)
      obj.AdjElements{end + 1} = element;
    end

    function name = getName(obj)
      name = obj.Name;
    end
    function obj = SetId(obj,id)
      obj.Id = id;
    end
  end
end