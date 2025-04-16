#!/usr/bin/env fish

# This script generates a series of images using the chafa command with different symbol combinations.
# I use it for creating Fastfetch txt logos :)
# https://www.imagetools.org/trim usefull for trimming images

if test (count $argv) -eq 0
    echo "Usage: gen.fish <file.png>"
    exit 1
end

set input_png $argv[1]

set types all none space solid stipple block border diagonal dot quad half hhalf vhalf inverted braille technical geometric ascii wedge wide
set num (count $types)

# Loop through only unique unordered combinations without self pairs.
for i in (seq 1 $num)
    set type1 $types[$i]
    for j in (seq (math $i + 1) $num)
        set type2 $types[$j]
        set combination "$type1+$type2"
        echo "Creating with type $combination"
        nix run nixpkgs#chafa -- -s 24x11 -w 9 --symbols $combination --view-size 24x11 $input_png
        # chafa -s 23x12 -w 9 --stretch --symbols $combination --view-size 23x12 $input_png
    end
end
