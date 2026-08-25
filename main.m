filename = 'input_netlist.txt';

raw_netlist = strsplit(fileread(filename), {'\r\n', '\n', '\r'});
lines = strtrim(raw_netlist(:));

% Remove inline comments beginning with ;, #, $, or %
lines = regexprep(lines, '[;#$%].*$', '');
lines = strtrim(lines);

% Remove blank lines and full-line comments
commentLine = startsWith(lines, {'*', '#', ';', '%'});
netlist_lines = lines(~cellfun(@isempty, lines) & ~commentLine);

disp(netlist_lines);

% Store node names as strings
nodes = strings(0, 1);

for i = 1:numel(netlist_lines)

  % Split on one or more whitespace characters
  words = strsplit(netlist_lines{i});

  if words{1}(1) == "."
    continue
  end

  % Return the updated nodes array
  nodes = addNode(words, nodes);

  switch upper(words{1}(1))
    case "."
      disp("dot discovered");
    case "V"
      disp("its voltage");
    case "I"
      disp("current");
    case "R"
      disp("resistor");
    case "L"
      disp("inductor");
    case "C"
      disp("capacitor");
    case "E"
      disp("VCVS");
    case "F"
      disp("CCCS");
    case "G"
      disp("VCCS");
    case "H"
      disp("CCVS");
    otherwise
      disp("unknown element");
  end
end

disp(nodes);


function nodes = addNode(words, nodes)
n1 = string(words{2});
n2 = string(words{3});

if ~ismember(n1, nodes)
  nodes(end + 1, 1) = n1;
end

if ~ismember(n2, nodes)
  nodes(end + 1, 1) = n2;
end
end