function value = valParse(inputText)

inputText = char(inputText);

inputText = replace(inputText, 'R', '.');
inputText = replace(inputText, 'r', '.');

suffixIndex = 0;

for i = 1:length(inputText)
  asciiValue = double(inputText(i));

  isUppercaseLetter = asciiValue >= double('A') && ...
    asciiValue <= double('Z');

  isLowercaseLetter = asciiValue >= double('a') && ...
    asciiValue <= double('z');

  if isUppercaseLetter || isLowercaseLetter
    suffixIndex = i;
    break;
  end
end

% Divide into number and suffix portions
if suffixIndex == 0
  numberPart = inputText;
  suffixPart = '';
else
  numberPart = inputText(1:suffixIndex-1);
  suffixPart = inputText(suffixIndex:end);
end

% Parse the number
number = str2double(numberPart);

if isnan(number)
  error("Invalid numeric value: %s", numberPart);
end

% Determine multiplier
if isempty(suffixPart)
  multiplier = 1;
elseif length(suffixPart) >= 3 && ...
    upper(suffixPart(1:3)) == "MEG"

  multiplier = 1e6;
else
  switch suffixPart(1)
    case {'T', 't'}
      multiplier = 1e12;

    case {'G', 'g'}
      multiplier = 1e9;

    case 'M'
      multiplier = 1e6;

    case 'k'
      multiplier = 1e3;

    case 'm'
      multiplier = 1e-3;

    case {'u', 'µ', 'μ'}
      multiplier = 1e-6;

    case 'n'
      multiplier = 1e-9;

    case 'p'
      multiplier = 1e-12;

    case 'f'
      multiplier = 1e-15;

    otherwise
      error("Unknown SPICE suffix: %s", suffixPart);
  end
end

value = number * multiplier;
end