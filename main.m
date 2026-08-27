
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

print_map(elements);

% real loop
vs_count = 1;
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
  elseif element.Type==Device.CurrentSource
    if n1~=0
      I_mat(n1,1) = I_mat(n1,1)-element.Value;
    end
    if n2~=0
      I_mat(n2,1) = I_mat(n2,1)+element.Value;
    end
  elseif element.Type == Device.VoltageSource
    disp("i am reading voltage source")
    I_mat(n_nodes + vs_count - 1, 1) = I_mat(n_nodes + vs_count - 1, 1) + element.Value;
    if (n1~=0)
      disp("vs node 1 analysis")
      G_mat(n_nodes + vs_count - 1, n1) = G_mat(n_nodes + vs_count - 1, n1) + 1;
      G_mat(n1, n_nodes + vs_count - 1) = G_mat(n1, n_nodes + vs_count - 1) + 1;
    end
    if (n2 ~=0)
      disp("vs node 2 analsysi")
      G_mat(n_nodes + vs_count - 1, n2) = G_mat(n_nodes + vs_count - 1, n2) - 1;
      G_mat(n2, n_nodes + vs_count - 1) = G_mat(n2, n_nodes + vs_count - 1) - 1;
    end
    voltage_sources(end+1) = element;
    vs_count = vs_count + 1;
    disp("analysis vs end")
    disp(I_mat)

  elseif element.Type == Device.VCVS
    first_node = nodes(element.DependsOn{1}).Id;
    second_node = nodes(element.DependsOn{2}).Id;
    if (first_node ~= 0)
      G_mat(n_nodes + vs_count - 1, first_node) = G_mat(n_nodes + vs_count - 1, first_node) - element.Value;
      G_mat(first_node, n_nodes + vs_count - 1) = G_mat(n_nodes + vs_count - 1, first_node) - element.Value;
    end
    if (second_node ~= 0)
      G_mat(n_nodes + vs_count - 1, first_node) = G_mat(n_nodes + vs_count - 1, first_node) + element.Value;
    end
    vs_count = vs_count + 1;
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