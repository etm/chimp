```bash
gem install cheap-impression-presenter
```

It wont work in a windows terminal for now.

You can utilize 'figlet' (chimp has a plugin).

You can utilize 'img2sixel' if you want to display graphics on a terminal with
sixel support (chimp has a sixel plugin).

You can utilize 'magick' (ImageMagick 7) if you want to display graphics on a
terminal with kitty graphics support, e.g. kitty, Ghostty, WezTerm (chimp has a
kitty plugin).

The pic plugin uses whichever of the two your terminal supports.

You can utilize 'inkscape' if you want to display svgs as graphics on your
terminal, or include them in the PDF output.

The PDF output (chimp -o pdf) uses the DejaVu Sans Mono font if it is
installed. Otherwise Courier is used, which lacks some characters (e.g. box
drawing).
