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
    loop do
      case $stdin.getch
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
  rescue WinchErrror
   [0,0]
  end
end #}}}

module Chimp
  class Parser

    class Screen < Output
      #### Optional functions called when a tree is tranformed to output ####
      #### mO + patternname for opening tags ####
      #### mC + patternname for closing tags ####

      def initialize() #{{{
        @scounter = @ccounter = 0
        @what = ''
        @last = 0
        @skip = -1

        @format = Pastel.new
        @screen = Window

        @screen.init
      end #}}}

      def finish_output #{{{
        @screen.set_pos 0,  @screen.lines
        @screen.print ' ' * (@screen.columns - 5)
        @screen.set_pos 0, @screen.lines
      end #}}}

      def mPP_WHAT(data)
        @what = data
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
        @screen.clear
        lines = @screen.lines
        columns = @screen.columns
        @screen.set_pos 0, lines-1
        @screen.print "-"*columns
        @screen.set_pos 0, lines
        @screen.print @what
        num = "#{c.userdata}/#{@scounter}"
        @screen.set_pos columns-num.length, lines
        @screen.print num
        @screen.set_pos 0, 0
        #}}}
      end

      def mPP_INCREMENTAL(c,tree,i)
        @last = c.close
      end
      def mOP_INCREMENTAL(c,tree)
        x, y = @screen.get_pos
        c.userdata = { :x => x, :y => y }
      end
      def mCP_INCREMENTAL(c,tree,i)
        return if @skip > i
        @skip = -1
        begin
          if @last == i
            lines = @screen.lines
            columns = @screen.columns
            @screen.set_pos 0, lines
            @screen.print "Press q to finish making a cheap impression."
          end
          begin
          ch = @screen.getch
          rescue Window::WinchError
            ch = :refresh
          end
        end while @last == i && ![:previous, :exit, :refresh].include?(ch)
        case ch
          when :previous
            #{{{
            pos = c.open-1
            tag = tree[pos]
            if tag.ttype == "P_SLIDES"
              if pos ==  0
                raise TagMoveEvent, pos
              else
                raise TagMoveEvent, tree[pos-1].open
              end
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
              @screen.print x.to_s + ',' + y.to_s
              @screen.print ' ' * howmuch
              @screen.set_pos tag.userdata[:x], tag.userdata[:y]
              ####
              raise TagMoveEvent, pos
            end
            #}}}
          when :refresh
            #{{{
            (c.open-1).downto(0) do |b|
              if tree[b].class == OpenTag && tree[b].ttype == "P_SLIDES"
                @skip = i
                raise TagMoveEvent, b
              end
            end
            #}}}
          when :exit
            @screen.finish
            exit
        end
      end
      def mOP_INCLUDE(data)
        require File::dirname(__FILE__) + "/../plugins/#{data[:name]}.rb"
        @screen.print eval('Chimp::Plugin::' + data[:name].upcase).new(data[:what]).process(data[:parameters],data[:additional])
      end
      def mOP_RANGE(data)
        require File::dirname(__FILE__) + "/../plugins/#{data[:name]}.rb"
        @screen.print eval('Chimp::Plugin::' + data[:name].upcase).new(data[:what]).process(data[:parameters])
      end

      def string(c,i,tree,data)
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
