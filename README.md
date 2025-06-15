CHIMP - Cheap IMpression Presenter
==================================

           __        _____
      ___ / /___    / _ \ \ ___
     / __| |/ _ \  | | | | |__ \
    | (__| | (_) | | |_| | |__) |
     \___| |\___(_|_)____| |___/
          \_\           /_/

Make a cheap impression. Present via terminal.

```gem install chimp```

It has a simple syntax:

    #what: the title of presentation

    --- splits slides

    +++ slides parts to appear

    !!Bold Text!!
    ``Red Text``
    %%Blue Text%%
    ~~Center Text

Everything else is in plugins. The following plugins are existing for now:

* Sixel: display graphics in the terminal: `` ```sixel name.png``.
* Figlet: display fancy ascii text: `` ```figlet FANCY_TEXT``.
* Line Numbers: display line numbers beforce any text.
~~~text
```figlet
Line
Line
Line
```
~~~

During presenting you can use the usual button for navigating. In addition, you
can use ``q`` to quit the presentation, and ``r`` to refresh the screen.

Check out the examples.

History & Thanks
================

Amy Hoy allowed me to use the logo for CHIMP all the way back in 2009. The
CHIMP was written as an icebreaker for the curucamp, which was a ruby
un-conference in 2009 in Vienna. We had fun, and many cool people from the
community attended.

I am still using the CHIMP for scientifc presentations, and as sixel terminals
finally are more common, I tried to polish it up (2025) and make it available
for easy consumption. Maybe you like it. I use it because I can create
presentations faster than in PP, KN, other programs. Most of the work goes
into graphics anyway, which I create with dedicated tools.

Drop me a note if you want to be a contributor, or send me merge request if you
have created some plugins. Creating plugins is very simple :-)

Missing Features
================

Presenting is nice. A PDF output mode would be useful. To send the presentation
to people in one file.

LICENSE
=======

GPL 3.0 or later.
