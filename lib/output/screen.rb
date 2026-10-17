require 'pastel'
require 'tty-screen'
require 'io/console'

module Window #{{{
  class WinchError < Exception; end

  def self::sync_begin()
    $stdout << "\e[?2026h"
    $stdout.flush
  end
  def self::sync_end()
    $stdout << "\e[?2026l"
    $stdout.flush
  end

  def self::init()
    self::sync_begin
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
    self::sync_end
    nil
  end
  def self::getch()
    self::sync_end
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
  ensure
    self::sync_begin
  end
  def self::lines()
    TTY::Screen.lines
  end
  def self::columns()
    TTY::Screen.columns
  end
  #### how often the screen was cleared; plugins check if what they
  #### drew is still there
  def self::cleared()
    @cleared || 0
  end
  def self::clear()
    @cleared = cleared + 1
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
        @x, @y = @screen.get_pos
        @drawn = []
        c.userdata = { :x => @x, :y => @y, :drawn => @drawn }
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
              ### erase only what this step has drawn (pictures next to it stay), then wait at the end of the previous step again
              step = tree[c.open].userdata
              step[:drawn].each do |x1,y1,x2,y2,erase|
                y1.upto(y2) do |y|
                  @screen.set_pos x1, y
                  @screen.print ' ' * (x2-x1+1)
                end
                erase.call if erase
              end
              @screen.set_pos step[:x], step[:y]
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

      #### plugins may return the area they drew as [x1,y1,x2,y2],
      #### otherwise the whole lines they printed on count an
      #### optional fifth element is called to erase, e.g., kitty pics
      def process(data)
        require File::dirname(__FILE__) + "/../plugins/#{data[:name]}.rb"
        area = eval('Chimp::Plugin::' + data[:name].upcase).new.process(data[:what],data[:parameters],@screen,data[:additional])
        return unless @drawn
        x, y = @screen.get_pos
        @drawn << (area.is_a?(Array) && [4, 5].include?(area.length) ? area : [1, @y, @screen.columns, y])
        @x, @y = x, y
      end
      private :process

      def mOP_INCLUDE(data)
        process data
      end
      def mOP_RANGE(data)
        process data
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
          @x += (len - data) / 2 if @drawn
        end
      end
      def mCP_CENTER(data)
        string "\n"
      end

      def string(data)
        ### remember which part of which line the current step prints, so going back can erase exactly that
        data.split(/(\n)/).each do |part|
          if part == "\n"
            @x = 1
            @y += 1
          elsif !part.empty?
            @drawn << [@x, @y, @x+part.length-1, @y]
            @x += part.length
          end
        end if @drawn
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
