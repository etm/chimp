require 'hexapdf'
require 'fileutils'
require_relative 'screen'

module Chimp
  class Parser

    class Pdf < Screen
      #### solarized light, #theme: in the header overrides single colors, e.g.
      #### #theme: background=#002b36 text=#839496 bold=#93a1a1 footer=#586e75
      THEME = {
        :background => 'fdf6e3', :text => '657b83', :bold => '586e75',
        :red => 'dc322f', :blue => '268bd2', :footer => '93a1a1'
      }
      FONTS = [
        %w(/usr/share/fonts/dejavu-sans-mono-fonts/DejaVuSansMono.ttf /usr/share/fonts/dejavu-sans-mono-fonts/DejaVuSansMono-Bold.ttf),
        %w(/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf /usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf),
        %w(/usr/share/fonts/TTF/DejaVuSansMono.ttf /usr/share/fonts/TTF/DejaVuSansMono-Bold.ttf),
        %w(/Library/Fonts/DejaVuSansMono.ttf /Library/Fonts/DejaVuSansMono-Bold.ttf)
      ]
      WIDTH  = 960 # 16:9 page in points
      HEIGHT = 540
      MARGIN = 20

      #### a virtual terminal that collects what is printed into a character grid {{{
      class Terminal
        attr_reader :columns, :lines, :images

        def initialize(columns,lines,pdf)
          @columns = columns
          @lines = lines
          @pdf = pdf
          clear
        end

        def clear
          @grid = Array.new(@lines) { Array.new(@columns) }
          @images = []
          @x = @y = 1
          @bold = false
          @color = nil
          self
        end

        def set_pos(x,y)
          @x = x < 1 ? 1 : x
          @y = y < 1 ? 1 : y
          self
        end
        def get_pos
          [@x, @y]
        end

        def print(a)
          a.to_s.scan(/\e\[([\d;]*)m|(\r?\n)|(.)/m) do |sgr,nl,char|
            if sgr
              sgr.split(';').map(&:to_i).each do |code|
                case code
                  when 0 then @bold = false; @color = nil
                  when 1 then @bold = true
                  when 31 then @color = :red
                  when 34 then @color = :blue
                end
              end
            elsif nl
              @x = 1
              @y += 1
            else
              if @x > @columns # deferred autowrap, like a real terminal
                @x = 1
                @y += 1
              end
              @grid[@y-1][@x-1] = [char, @bold, @color] if @y <= @lines
              @x += 1
            end
          end
        end

        ### the image is placed at the cursor, the cursor moves below it
        def image(what,width,fname)
          img, rows = @pdf.load_image(what,width,fname)
          return print("Image #{what} not found.\n") if img.nil?
          @images << { :file => img, :x => @x, :y => @y, :width => width }
          @y += rows
        end

        ### yields runs of equally formatted text: x, y, text, bold, color
        def each_run
          @grid.each_with_index do |row,y|
            x = 0
            while x < row.length
              if row[x].nil? || row[x][0] == ' '
                x += 1
                next
              end
              start = x
              text = ''
              while x < row.length && row[x] && row[x][1..2] == row[start][1..2]
                text << row[x][0]
                x += 1
              end
              yield start + 1, y + 1, text.rstrip, row[start][1], row[start][2]
            end
          end
        end
      end #}}}

      #### the pdf is written next to the presentation: talk.txt -> talk.pdf
      def initialize(fname) #{{{
        @scounter = @ccounter = 0
        @what = ''
        @size = SIZE
        @last = 0
        @skip = -1
        @templates = []

        @fname = File.basename(fname,'.*') + '.pdf'
        @theme = THEME.dup
        @doc = HexaPDF::Document.new
        @doc.config['font.on_missing_glyph'] = proc { |char,font| font.decode_utf8('?').first }
        regular, bold = FONTS.find { |f| f.all? { |e| File.exist?(e) } }
        @font = @doc.fonts.add(regular || 'Courier')
        @bold = @doc.fonts.add(bold || 'Courier', **(bold ? {} : { :variant => :bold }))
        @page = nil
      end #}}}

      #### the slide always has @size lines, the last two of which are the footer
      def finish_prepare #{{{
        @rowh = (HEIGHT - 2 * MARGIN).to_f / @size
        @fsize = @rowh / 1.2
        @cw = @font.decode_utf8('M').first.width * @fsize / 1000.0
        columns = ((WIDTH - 2 * MARGIN) / @cw).floor
        @left = (WIDTH - columns * @cw) / 2.0
        @screen = Terminal.new(columns, @size - 2, self)
      end #}}}

      def finish_output #{{{
        @doc.write(@fname, :optimize => true)
        nil
      end #}}}

      def mPP_THEME(data) #{{{
        data.split.each do |pair|
          key, color = pair.split('=',2)
          unless THEME.key?(key.to_sym) && color =~ /\A#?(\h{6})\z/
            abort "Invalid #theme: entry '#{pair}', use KEY=#RRGGBB with KEY one of: #{THEME.keys.join(', ')}"
          end
          @theme[key.to_sym] = $1
        end
      end #}}}

      def mOP_SLIDES(c,tree)
        @page = c.userdata
        @screen.clear
        template tree
      end
      #### every +++ step (animation frame) becomes a page of its own
      def mOP_INCREMENTAL(c,tree); end
      def mCP_INCREMENTAL(c,tree,i)
        render
      end

      #### plugins only need to prepare things for the terminal
      def mPP_INCLUDE(data); end
      def mPP_RANGE(data); end

      #### an image in the pdf, svgs are converted to pdf with inkscape (cached)
      def load_image(what,width,fname) #{{{
        src = File.join(File.dirname(fname),what)
        return unless File.exist?(src)
        if what =~ /\.svg$/
          cache = File.join(File.dirname(fname),'.' + File.basename(fname,'.*'),"#{what.gsub('/','_')}.pdf")
          unless File.exist?(cache) && File.mtime(cache) >= File.mtime(src)
            FileUtils.mkdir_p(File.dirname(cache))
            system 'inkscape', '-D', '--export-type=pdf', src, '-o', cache, :err => File::NULL
          end
          src = cache
        end
        img = @doc.images.add(src)
        w, h = img.is_a?(HexaPDF::Type::Form) ? [img.box.width, img.box.height] : [img.width, img.height]
        [img, (width * @cw * h / w / @rowh).ceil]
      end #}}}

      def render #{{{
        return if @page.nil?
        canvas = @doc.pages.add([0, 0, WIDTH, HEIGHT]).canvas
        canvas.fill_color(@theme[:background]).rectangle(0, 0, WIDTH, HEIGHT).fill

        ### images first, text that follows goes on top. an image covers
        ### what was below (e.g. for animations), so paint the background first.
        @screen.images.each do |i|
          x = @left + (i[:x] - 1) * @cw
          w = i[:width] * @cw
          obj = i[:file]
          h = w * (obj.is_a?(HexaPDF::Type::Form) ? obj.box.height / obj.box.width : obj.height.to_f / obj.width)
          y = top(i[:y]) - h
          canvas.fill_color(@theme[:background]).rectangle(x, y, w, h).fill
          canvas.image(obj, :at => [x, y], :width => w)
        end

        @screen.each_run do |x,y,text,bold,color|
          canvas.font(bold ? @bold : @font, :size => @fsize)
          canvas.fill_color(@theme[color || (bold ? :bold : :text)])
          canvas.text(text, :at => [@left + (x - 1) * @cw, baseline(y)])
        end

        ### footer
        canvas.stroke_color(@theme[:footer]).line_width(0.5)
        canvas.line(@left, top(@size - 1) - @rowh / 2, @left + @screen.columns * @cw, top(@size - 1) - @rowh / 2).stroke
        canvas.font(@font, :size => @fsize).fill_color(@theme[:footer])
        canvas.text(@what, :at => [@left, baseline(@size)])
        num = "#{@page}/#{@scounter}"
        canvas.text(num, :at => [@left + (@screen.columns - num.length) * @cw, baseline(@size)])
      end #}}}

      def top(y)
        HEIGHT - MARGIN - (y - 1) * @rowh
      end
      def baseline(y)
        top(y) - (@rowh + @fsize * 0.6) / 2
      end
      private :render, :top, :baseline

    end
  end
end
