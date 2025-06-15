CHIMP - Cheap IMpression Presenter
==================================

           __        _____
      ___ / /___    / _ \ \ ___
     / __| |/ _ \  | | | | |__ \
    | (__| | (_) | | |_| | |__) |
     \___| |\___(_|_)____| |___/
          \_\           /_/

Make a cheap impression. Present via terminal.

```gem install cheap-impression-presenter```

It has a simple syntax:

    #what: the title of presentation

    --- splits slides

    +++ slides parts to appear

    !!Bold Text!!
    ``Red Text``
    %%Blue Text%%
    ~~Center Text

Everything else is in plugins. The following plugins are existing for now:

* Sixel: display graphics in the terminal: `` ```sixel,20 name.png``.
  * The parameter 20 denotes the size in characters.
  * You can add right or center as an additional parameter to align the picture.
  * If the picture is right aligned text is added on the left of the picture instead of beneath.  
* Figlet: display fancy ascii text: `` ```figlet FANCY_TEXT``.
  * You can add right or center as a parameter to align the fancy text.
  * If the fancy text is right aligned normal text is added on the left of the fancy text instead of beneath.  
* Line Numbers: display line numbers beforce any text (mostly used for code :-).
~~~text
```figlet
Line
Line
Line
```
~~~

Run the presentation with:

```bash
chimp mypresentation.txt
```

While presenting you can use the usual button for navigating. In addition, you
can use ``q`` to quit the presentation, and ``r`` to refresh the screen. I suggest zooming
the terminal until about 30 lines are visible. To make this easy a lightgray ``^`` character is
visible in the rightmost column of the terminal. Zoom until the ``^`` character is no longer visible for
the most audience friendly results.

Check out the examples.

History & Thanks
================

Amy Hoy allowed me to use the monkey ascii art she created for the CHIMP all the way back in 2009. The
CHIMP was written as an icebreaker for the curucamp, which was a ruby
un-conference in 2009 in Vienna. We had fun, and many cool people from the
community attended.

I am still using the CHIMP for scientifc presentations, and as sixel terminals
finally are more common, I tried to polish the CHIMP up (2025) and make it available
for easy consumption. Maybe you like it. I use it because I can create
presentations faster than in PP, KN, other programs. Most of the work goes
into graphics anyway, which I create with dedicated tools.

Drop me a note if you want to be a contributor, or send me merge request if you
have created some plugins. Creating plugins is very simple :-)

Missing Features
================

Presenting is nice. A PDF output mode would be useful ... to send the presentation
to people in one file.

LICENSE
=======

GPL 3.0 or later.
