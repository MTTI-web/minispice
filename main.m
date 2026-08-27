
function print_map(nodes)
keysList = keys(nodes);

for i = 1:numel(keysList)
  key = keysList{i};
  value = nodes(key);

  fprintf("Key: %s\n", key);
  disp(value);
end
end

function nodes = addNode(words, nodes)
n1 = string(words{2});
n2 = string(words{3});

if ~isKey(nodes,n1)
  nodes(n1) = Node(n1);
end

if ~isKey(nodes,n2)
  nodes(n2) = Node(n2);
end
end

% parse netlist
filename = 'input_netlist.txt';

raw_netlist = strsplit(fileread(filename), {'\r\n', '\n', '\r'});
lines = strtrim(raw_netlist(:));

lines = regexprep(lines, '[;#$%].*$', '');
lines = strtrim(lines);
commentLine = startsWith(lines, {'*', '#', ';', '%'});
netlist_lines = lines(~cellfun(@isempty, lines) & ~commentLine);

nodes = containers.Map();
elements = containers.Map();

% add nodes, dont consider .end , .tran etc
for i = 1:numel(netlist_lines)
  words = strsplit(netlist_lines{i});
  if words{1}(1) == "."
    continue
  end
  nodes = addNode(words, nodes);
end


n_vs = 0; % number of voltage sources.

% add elements
for i = 1:numel(netlist_lines)
  words = strsplit(netlist_lines{i});

  if words{1}(1)=="."
    continue;
  end

  element = Element(words);

  elements(words{1}) = element;

  nodes(words{2}).addElement(element);
  nodes(words{3}).addElement(element);
  if element.Type == Device.VoltageSource || element.Type == Device.VCVS ||element.Type == Device.CCVS
    n_vs = n_vs + 1;
    element.VS_ID = n_vs;
  end
end


% handling no ground
refNode = "0";

if ~isKey(nodes, "0")
  refNodes = keys(nodes);
  refNode = refNodes{1};
end

% give ID to each node
i = 1;
for k = keys(nodes)
  if k~=refNode
    nodes(k{1}).SetId(i);
    i=i+1;
  end
end
clear i;


n_nodes = length(keys(nodes));

% initializing known matrices
G_mat = zeros(n_nodes + n_vs - 1, n_nodes + n_vs -1);
I_mat = zeros(n_nodes + n_vs - 1, 1);

% real loop
voltage_sources = Element.empty(0,1);
for el = keys(elements)
  element = elements(el{1});
  n1 = nodes(element.Nodes{1}).Id;
  n2 = nodes(element.Nodes{2}).Id;
  if element.Type==Device.Resistor
    if n1==0
      G_mat(n2,n2) = G_mat(n2,n2) + 1/element.Value;
    elseif n2==0
      G_mat(n1,n1) = G_mat(n1,n1) + 1/element.Value;
    else
      G_mat(n1,n1) = G_mat(n1,n1) + 1/element.Value;
      G_mat(n2,n2) = G_mat(n2,n2) + 1/element.Value;
      G_mat(n1,n2) = G_mat(n1,n2) - 1/element.Value;
      G_mat(n2,n1) = G_mat(n2,n1) - 1/element.Value;
    end
  end
  if element.Type==Device.CurrentSource
    if n1~=0
      I_mat(n1,1) = I_mat(n1,1)-element.Value;
    end
    if n2~=0
      I_mat(n2,1) = I_mat(n2,1)+element.Value;
    end
  end
  if element.Type == Device.VoltageSource
    I_mat(n_nodes + element.VS_ID - 1, 1) = I_mat(n_nodes + element.VS_ID - 1, 1) + element.Value;
  end

  if element.Type == Device.VCVS
    first_node = nodes(element.DependsOn{1}).Id;
    second_node = nodes(element.DependsOn{2}).Id;
    if (first_node ~= 0)
      G_mat(n_nodes + element.VS_ID - 1, first_node) = G_mat(n_nodes + element.VS_ID - 1, first_node) - element.Value;
    end
    if (second_node ~= 0)
      G_mat(n_nodes + element.VS_ID - 1, second_node) = G_mat(n_nodes + element.VS_ID - 1, second_node) + element.Value;
    end
  end
  if element.Type==Device.CCVS
    device = elements(element.DependsOn);
    switch device.Type
      case Device.Resistor
        first_node = nodes(device.Nodes{1}).Id;
        second_node = nodes(device.Nodes{2}).Id;
        if (first_node ~= 0)
          G_mat(n_nodes + element.VS_ID - 1, first_node) = G_mat(n_nodes + element.VS_ID - 1, first_node) - element.Value/device.Value;
        end
        if (second_node ~= 0)
          G_mat(n_nodes + element.VS_ID - 1, second_node) = G_mat(n_nodes + element.VS_ID - 1, second_node) + element.Value/device.Value;
        end
      case Device.CurrentSource
        I_mat(n_nodes + element.VS_ID - 1, 1) = I_mat(n_nodes + element.VS_ID - 1, 1) + element.Value*device.Value;
      case Device.VoltageSource
        G_mat(element.VS_ID+n_nodes-1,device.VS_ID + n_nodes -1) = G_mat(element.VS_ID+n_nodes-1,device.VS_ID + n_nodes -1) - element.Value;
      case Device.CCVS
        G_mat(element.VS_ID+n_nodes-1,device.VS_ID + n_nodes -1) = G_mat(element.VS_ID+n_nodes-1,device.VS_ID + n_nodes -1) - element.Value;
      case Device.VCVS
        G_mat(element.VS_ID+n_nodes-1,device.VS_ID + n_nodes -1) = G_mat(element.VS_ID+n_nodes-1,device.VS_ID + n_nodes -1) - element.Value;
      case Device.VCCS %TODO
      case Device.CCCS %TODO
      otherwise
    end
  end

  if element.Type==Device.VCCS
    first_node = nodes(element.DependsOn{1}).Id;
    second_node = nodes(element.DependsOn{2}).Id;
    if (first_node ~= 0 && n1~=0)
      G_mat(n1 , first_node) = G_mat(n1, first_node) + element.Value;
    end
    if (second_node ~= 0 && n2~=0)
      G_mat(n2 , second_node) = G_mat(n2,second_node) + element.Value;
    end
    if (second_node ~= 0 && n1~=0)
      G_mat(n1 , second_node) = G_mat(n1, second_node) - element.Value;
    end
    if (first_node ~= 0 && n2~=0)
      G_mat(n2 , first_node) = G_mat(n2, first_node) - element.Value;
    end
  end

  if element.Type == Device.CCCS
    device = elements(element.DependsOn);
    t = element.Value / device.Value;
    disp(device);
    switch device.Type
      case Device.Resistor
        if n1 ~= 0 && nodes(device.Nodes{1}).Id ~= 0
          disp(1);
          G_mat(n1, nodes(device.Nodes{1}).Id) = G_mat(n1, nodes(device.Nodes{1}).Id) + t;
        end
        if n2 ~= 0 && nodes(device.Nodes{2}).Id ~= 0
          disp(2);
          G_mat(n2, nodes(device.Nodes{2}).Id) = G_mat(n2, nodes(device.Nodes{2}).Id) + t;
        end
        if n1 ~= 0 && nodes(device.Nodes{2}).Id ~= 0
          disp(3);
          G_mat(n1, nodes(device.Nodes{2}).Id) = G_mat(n1, nodes(device.Nodes{2}).Id) - t;
        end
        if n2 ~= 0 && nodes(device.Nodes{1}).Id ~= 0
          disp(4);
          G_mat(n2, nodes(device.Nodes{1}).Id) = G_mat(n2, nodes(device.Nodes{1}).Id) - t;
        end
      otherwise
    end
  end

  if element.Type==Device.VoltageSource || element.Type==Device.VCVS || element.Type == Device.CCVS
    if (n1~=0)
      G_mat(n_nodes + element.VS_ID - 1, n1) = G_mat(n_nodes + element.VS_ID - 1, n1) + 1;
      G_mat(n1, n_nodes + element.VS_ID - 1) = G_mat(n1, n_nodes + element.VS_ID - 1) + 1;
    end
    if (n2 ~=0)
      G_mat(n_nodes + element.VS_ID - 1, n2) = G_mat(n_nodes + element.VS_ID - 1, n2) - 1;
      G_mat(n2, n_nodes + element.VS_ID - 1) = G_mat(n2, n_nodes + element.VS_ID - 1) - 1;
    end
    voltage_sources(end+1) = element;
  end
end

disp(G_mat);


% solve matrix and print
V = G_mat\I_mat;

disp(V)

for k = keys(nodes)
  if nodes(k{1}).Id~=0
    fprintf("Voltage of %s is %f\n",k{1},V(nodes(k{1}).Id));
  end
end

for v = 1:length(voltage_sources)
  vs = voltage_sources(v);
  fprintf("Current in %s from %s to %s is %f\n",vs.Name,vs.Nodes{1},vs.Nodes{2},V(n_nodes+v-1));
end

% print_map(elements);