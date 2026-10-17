require 'pastel'
require 'tty-screen'
require 'io/console'

module Window #{{{
  class WinchError < Exception; end
  def self::init()
    self::clear
    $stdout << "\e[?25l"
    $stdout.flush
    Signal.trap("WINCH") do
      raise WinchError, 'nope'
    end
    nil
  end
  def self::finish()
    self::clear
    self::set_pos 0, 0
    $stdout << "\e[?25h"
    $stdout.flush
    nil
  end
  def self::getch()
    number = nil
    loop do
      ch = $stdin.getch
      if number
        if ch =~ /\d/
          number << ch
          next
        end
        return [:goto, number.to_i] if ch == "\r" && !number.empty?
        number = nil
      end
      case ch
        when 'g' then number = ''
        when 'r' then return :refresh
        when 'q' then return :exit
        when "\r" then return :enter
        when "\e"
          case $stdin.getch
          when '['
            case $stdin.getch
              when 'A' then return :previous
              when 'B' then return :next
              when 'C' then return :next
              when 'D' then return :previous
            end
          end
      end
    end
  end
  def self::lines()
    TTY::Screen.lines
  end
  def self::columns()
    TTY::Screen.columns
  end
  def self::clear()
    $stdout << "\e[2J"
    $stdout.flush
    self
  end
  def self::set_pos(x,y)
    $stdout << "\e[#{y};#{x}H"
    $stdout.flush
    self
  end
  def self::print(a)
    $stdout.write a
    $stdout.flush
  end
  def self::get_pos
    res = ''
    $stdin.raw do |stdin|
      $stdout << "\e[6n"
      $stdout.flush
      while (c = $stdin.getc) != 'R'
        res << c if c
      end
    end
    m = res.match /(?<column>\d+);(?<row>\d+)/
    [ Integer(m[:row]), Integer(m[:column]) ]
  rescue WinchError
    [0,0]
  end
end #}}}

module Chimp
  class Parser

    class Screen < Output
      #### Optional functions called when a tree is tranformed to output ####
      #### mO + patternname for opening tags ####
      #### mC + patternname for closing tags ####

      attr_writer :goto

      def initialize(fname) #{{{
        @goto = nil
        @scounter = @ccounter = 0
        @what = ''
        @size = SIZE
        @last = 0
        @templates = []

        @format = Pastel.new
        @screen = Window

        @screen.init
      end #}}}

      def template(tree)
        @templates.each { |from,to| replay tree, from, to }
        @screen.set_pos 0, 0
      end

      def finish_output #{{{
        @screen.set_pos 0,  @screen.lines
        @screen.print ' ' * (@screen.columns - 5)
        @screen.set_pos 0, @screen.lines
      end #}}}

      def mPP_WHAT(data)
        @what = data
      end
      def mPP_SIZE(data)
        @size = data if data > 0
      end

      def mPP_SLIDES(c,tree)
        #{{{
        @scounter += 1
        @ccounter += 1
        c.userdata = @ccounter
        #}}}
      end
      def mOP_SLIDES(c,tree)
        #{{{
        ### after a reload, skip the slides before the one we were on
        raise TagSkipEvent if @goto && c.userdata < [@goto[0], @scounter].min
        @screen.clear
        lines = @screen.lines
        columns = @screen.columns
        @screen.set_pos 0, lines-1
        ### print footer, with a mark at the end
        @screen.print (lines > @size ? ("-"*(columns-1) + "^") : "-"*columns)
        @screen.set_pos 0, lines
        @screen.print @what
        num = "#{c.userdata}/#{@scounter}"
        @screen.set_pos columns-num.length+1, lines
        @screen.print num
        @screen.set_pos 0, 0
        template tree
        #}}}
      end

      def mPP_TEMPLATE(c,tree,i)
        @templates << [i+1, c.close-1]
      end
      def mOP_TEMPLATE(data)
        raise TagSkipEvent
      end

      def mPP_INCREMENTAL(c,tree,i)
        @last = c.close
      end
      def mOP_INCREMENTAL(c,tree)
        x, y = @screen.get_pos
        c.userdata = { :x => x, :y => y }
      end
      #### the slide the incremental closing at i belongs to, which step it is, and how many steps the slide has
      def position(tree,i)
        b = i.downto(0).find { |x| tree[x].class == OpenTag && tree[x].ttype == "P_SLIDES" }
        steps = tree[b..tree[b].close].select { |t| t.class == CloseTag && t.ttype == "P_INCREMENTAL" }
        [b, steps.index(tree[i]) + 1, steps.length]
      end
      private :position

      def mCP_INCREMENTAL(c,tree,i)
        ### after a reload, show the steps up to the one we were on without waiting
        if @goto
          b, step, steps = position(tree,i)
          return if step < [@goto[1], steps].min
          @goto = nil
        end
        ### on the first part of the first slide there is nothing to go back to
        pos = c.open-1
        first = tree[pos].ttype == "P_SLIDES" && tree[0...pos].none? { |t| t.class == OpenTag && t.ttype == "P_SLIDES" }
        begin
          if @last == i
            lines = @screen.lines
            columns = @screen.columns
            @screen.set_pos 0, lines
            @screen.print "Press 'q' to finish making a cheap impression..."
          end
          begin
          ch, slide = @screen.getch
          rescue Window::WinchError
            ch = :refresh
          end
        end while (first && ch == :previous) || (@last == i && ![:previous, :exit, :refresh, :goto].include?(ch))
        case ch
          when :goto
            #{{{
            slide = slide.clamp(1, @scounter)
            raise TagMoveEvent, tree.index { |t| t.class == OpenTag && t.ttype == "P_SLIDES" && t.userdata == slide }
            #}}}
          when :previous
            #{{{
            tag = tree[pos]
            if tag.ttype == "P_SLIDES"
              raise TagMoveEvent, tree[pos-1].open
            end
            if tag.ttype == "P_INCREMENTAL"
              pos = tag.open
              tag = tree[pos]
              columns = @screen.columns
              #### get current position
              x, y = @screen.get_pos
              #### how many spaces needed
              howmuch = ((y - tag.userdata[:y] + 1) * columns) - (columns - x) - tag.userdata[:x]
              @screen.set_pos tag.userdata[:x], tag.userdata[:y]
              # @screen.print x.to_s + ',' + y.to_s
              @screen.print ' ' * howmuch
              @screen.set_pos tag.userdata[:x], tag.userdata[:y]
              ####
              raise TagMoveEvent, pos
            end
            #}}}
          when :refresh
            #{{{
            ### reparse the presentation (it may have changed) and return to the same slide and step
            b, step, steps = position(tree,i)
            raise ReloadEvent, [tree[b].userdata, step]
            #}}}
          when :exit
            @screen.finish
            exit
        end
      end
      def mPP_INCLUDE(data)
        require File::dirname(__FILE__) + "/../plugins/#{data[:name]}.rb"
        eval('Chimp::Plugin::' + data[:name].upcase).new.prepare(data[:what],data[:parameters],data[:additional])
      end
      def mPP_RANGE(data)
        require File::dirname(__FILE__) + "/../plugins/#{data[:name]}.rb"
        eval('Chimp::Plugin::' + data[:name].upcase).new.prepare(data[:what],data[:parameters],data[:additional])
      end

      def mOP_INCLUDE(data)
        require File::dirname(__FILE__) + "/../plugins/#{data[:name]}.rb"
        eval('Chimp::Plugin::' + data[:name].upcase).new.process(data[:what],data[:parameters],@screen,data[:additional])
      end
      def mOP_RANGE(data)
        require File::dirname(__FILE__) + "/../plugins/#{data[:name]}.rb"
        eval('Chimp::Plugin::' + data[:name].upcase).new.process(data[:what],data[:parameters],@screen,data[:additional])
      end

      def mOP_STRONG(data); @screen.print "\e[1m"; end
      def mCP_STRONG(data); @screen.print "\e[0m"; end
      def mOP_RED(data); @screen.print "\e[0;31m"; end
      def mCP_RED(data); @screen.print "\e[0m"; end
      def mOP_BLUE(data); @screen.print "\e[0;34m"; end
      def mCP_BLUE(data); @screen.print "\e[0m"; end
      def mOP_STRONGRED(data); @screen.print "\e[1;31m"; end
      def mCP_STRONGRED(data); @screen.print "\e[0m"; end
      def mOP_STRONGBLUE(data); @screen.print "\e[1;34m"; end
      def mCP_STRONGBLUE(data); @screen.print "\e[0m"; end

      def mOP_CENTER(c,tree,i)
        ### only the visible text counts, not the markup
        data = tree[i+1...c.close].grep(String).sum(&:length)
        len = @screen.columns
        if len-data > 0
          @screen.print ' ' * ((len - data) / 2)
        end
      end
      def mCP_CENTER(data)
        @screen.print "\n"
      end

      def string(data)
        @screen.print(data)
      end

      def p(what)
        #{{{
        lines = @screen.lines
        @screen.set_pos 0, lines-1
        @screen.print what.inspect
        x, y = @screen.get_pos
        @screen.set_pos x, y
        @screen.getch
        #}}}
      end
      private :p

    end
  end
end
