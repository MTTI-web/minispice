filename = 'input_netlist.txt';

raw_netlist = strsplit(fileread(filename), {'\r\n', '\n', '\r'});
lines = strtrim(raw_netlist(:));

lines = regexprep(lines, '[;#$%].*$', '');
lines = strtrim(lines);
commentLine = startsWith(lines, {'*', '#', ';', '%'});
netlist_lines = lines(~cellfun(@isempty, lines) & ~commentLine);


nodes = containers.Map();

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

  disp(element);
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

% debugging area
% f(nodes)