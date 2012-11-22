require 'curses'

module Chimp
  class Parser

    class Screen < Output
      #### Optional functions called when a tree is tranformed to output ####
      #### mO + patternname for opening tags ####
      #### mC + patternname for closing tags ####
      
      def initialize()
        #{{{
        @scounter = @ccounter = 0
        @what = ''
        @last = 0
        @skip = -1
        Curses::init_screen
        if Curses::has_colors?
          bg = Curses::COLOR_BLACK 
          Curses::start_color 
          if Curses::respond_to?("use_default_colors")
            if Curses::use_default_colors
              bg = -1 
            end 
          end
          Curses::init_pair(1, Curses::COLOR_RED, bg)
          Curses::init_pair(2, Curses::COLOR_BLUE, bg)
        end
        Curses::cbreak
        Curses::noecho
        Curses::nonl
        Curses::curs_set 0
        @win = Curses::stdscr
        #}}}
      end

      def finish_output
        Curses::curs_set 1
        Curses::close_screen
      end
      
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
        @win::clear
        lines = @win.getmaxy
        columns = @win.getmaxx
        @win.mvaddstr(lines-2,0, "-"*columns) 
        @win.mvaddstr(lines-1,0, @what) 
        num = "#{c.userdata}/#{@scounter}"
        @win.mvaddstr(lines-1,columns-num.length, num) 
        @win.mvaddstr(0,0,'')
        #}}}
      end

      def mPP_INCREMENTAL(c,tree,i)
        @last = c.close
      end
      def mOP_INCREMENTAL(c,tree)
        x = []; y = []
        @win.getyx(y,x)
        c.userdata = { :x => x[0], :y => y[0] }
      end
      def mCP_INCREMENTAL(c,tree,i)
        return if @skip > i
        @skip = -1
        begin
          if @last == i
            lines = @win.getmaxy
            columns = @win.getmaxx
            @win.mvaddstr(lines-1,0, "Press ENTER to finish making a cheap impression." + (" "*columns)) 
          end
          ch = @win::getch
        end while @last == i && ![Curses::KEY_LEFT, Curses::KEY_RESIZE, Curses::KEY_REFRESH, Curses::KEY_RESET, 114, 13].include?(ch)
        case ch
          when Curses::KEY_LEFT
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
              columns = @win.getmaxx
              #### get current position
              x = []; y = []
              @win.getyx(y,x)
              x = x[0]
              y = y[0]
              #### how many spaces needed
              howmuch = ((y - tag.userdata[:y] + 1) * columns) - (columns - x) - tag.userdata[:x]
              @win.mvaddstr(tag.userdata[:y],tag.userdata[:x],' '*howmuch) 
              @win.mvaddstr(tag.userdata[:y],tag.userdata[:x],'')
              ####
              raise TagMoveEvent, pos
            end
            #}}}
          when Curses::KEY_RESIZE, Curses::KEY_REFRESH, Curses::KEY_RESET, 114
            #{{{
            (c.open-1).downto(0) do |b|
              if tree[b].class == OpenTag && tree[b].ttype == "P_SLIDES"
                @skip = i
                raise TagMoveEvent, b
              end  
            end
            #}}}
        end  
      end
      def mOP_RANGE(data)
        data.name.each do |n|
          require "plugins/#{n}"
          plug = eval(n.upcase).new

        end
      end

      def mOP_RED; set_color(1); end
      def mCP_RED; set_color(0); end
      def mOP_BLUE; set_color(2); end
      def mCP_BLUE; set_color(0); end
      def mOP_STRONG; @win::attron(Curses::A_BOLD); end
      def mCP_STRONG; @win::attroff(Curses::A_BOLD); end

      def string(data); @win::addstr data; end

      def set_color(color_pair)
        #{{{
        if Curses::respond_to?(:color_set)
          @win::color_set(color_pair, nil)
        else
          @win::attrset(Curses::COLOR_PAIR(color_pair))
        end
        #}}}
      end
      private :set_color

      def p(what)
        #{{{
        lines = @win.getmaxy
        @win.mvaddstr lines-1,0,what.inspect
        x = []; y = []
        @win.getyx(y,x)
        @win.mvaddstr y,x,''
        #}}}
      end
      private :p

    end
  end
end
