filename = 'input_netlist.txt';

raw_netlist = strsplit(fileread(filename), {'\r\n', '\n', '\r'});
lines = strtrim(raw_netlist(:));

lines = regexprep(lines, '[;#$%].*$', '');
lines = strtrim(lines);
commentLine = startsWith(lines, {'*', '#', ';', '%'});
netlist_lines = lines(~cellfun(@isempty, lines) & ~commentLine);

nodes = containers.Map();
elements = containers.Map();

for i = 1:numel(netlist_lines)
  words = strsplit(netlist_lines{i});
  if words{1}(1) == "."
    continue
  end
  nodes = addNode(words, nodes);
end


for i = 1:numel(netlist_lines)
  words = strsplit(netlist_lines{i});

  if words{1}(1)=="."
    continue;
  end
  if words{4}=="DC"
    words{4} = words{5};
  end
  element = Element(words{1},words{2},words{3},words{4});

  elements(words{1}) = element;

  nodes(words{2}).addElement(element);
  nodes(words{3}).addElement(element);
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

function f(nodes)
keysList = keys(nodes);

for i = 1:numel(keysList)
  key = keysList{i};
  value = nodes(key);

  fprintf("Key: %s\n", key);
  disp(value);
end
end

% handling no ground

refNode = "0";

if ~isKey(nodes, "0")
  refNodes = keys(nodes);
  refNode = refNodes{1};
end


i = 1;
for k = keys(nodes)
  if k~=refNode
    nodes(k{1}).SetId(i);
    i=i+1;
  end
end
clear i;

% incrementing matrix size by number of voltage sources
n_vs = 0;
elementKeys = keys(elements);
for i = 1:numel(elementKeys)
  if elements(elementKeys{i}).Type == Device.VoltageSource
    disp("voltage source found");
    n_vs = n_vs + 1;
  end
end

n_nodes = length(keys(nodes));

% initializing known matrices
G_mat = zeros(n_nodes + n_vs - 1, n_nodes-1);
I_mat = zeros(n_nodes + n_vs - 1, 1);

vs_count = 1;
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
    I_mat(n_nodes + vs_count - 1, 1) = element.Value;
    if (n1~=0)
      G_mat(n_nodes + vs_count - 1, n1) = 1;
      G_mat(n1, n_nodes + vs_count - 1) = 1;
    end
    if (n2 ~=0)
      G_mat(n_nodes + vs_count - 1, n2) = -1;
      G_mat(n2, n_nodes + vs_count - 1) = -1;
    end
  end
end
V = G_mat\I_mat;


for k = keys(nodes)
  if nodes(k{1}).Id~=0
    fprintf("Voltage of %s is %f\n",k{1},V(nodes(k{1}).Id));
  end
end

disp(V)
