require 'fileutils'
require 'base64'
require 'io/console'

module Chimp
  module Plugin
    class KITTY < Base
      @@placed = {} # [x,y] => [id, width, screen clears so far, what it replaced], the pictures on the screen
      #### pixel size of a character cell: from the terminal if it knows, else 10x21 as for sixel and the pdf
      def cell_size
        rows, cols, xpix, ypix = [0, 0, 0, 0].pack('S4').then { |buf| $stdout.ioctl(0x5413, buf); buf.unpack('S4') } # TIOCGWINSZ
        return [xpix / cols, ypix / rows] if xpix > 0 && ypix > 0
        [10, 21]
      rescue StandardError
        [10, 21]
      end

      # converted images are cached in .PRESENTATIONNAME/ next to the presentation
      def cache_file(what,width,fname)
        dir = File.join(File.dirname(fname),'.' + File.basename(fname,'.*'))
        File.join(dir,"#{what.gsub('/','_')}.#{width}.kitty.png")
      end

      #### kitty only takes png. the terminal scales it to the width, so it does not depend on the zoom
      #### (which would convert everything again for each zoom). as for sixel 10 pixels per character,
      #### and 5 bits per color, which keeps it small (it goes through the terminal, maybe via ssh)
      def png(what,width,fname)
        src = File.join(File.dirname(fname),what)
        pixels = width * 10
        cache = cache_file(what,width,fname)
        if File.exist?(cache) && File.exist?(src) && File.mtime(cache) >= File.mtime(src)
          return File.binread(cache)
        end
        convert = if what =~ /\.svg$/
          "inkscape -D -d 300 --export-type=png #{src} -o - | magick - -resize #{pixels}x -depth 5 png:-"
        else
          "magick #{src} -resize #{pixels}x -depth 5 png:-"
        end
        result = `#{convert}`
        if $?.success? && !result.empty?
          FileUtils.mkdir_p(File.dirname(cache))
          File.binwrite(cache,result)
        end
        result
      end

      def prepare(what,parameters,additional)
        return if parameters[0] !~ /\d/
        png(what,parameters[0].to_i,additional[:fname])
      end

      def process(what,parameters,screen,additional)
        if parameters[0] !~ /\d/
          screen.print 'Use ```kitty,NUM with NUM beeing the width if the picture in characters.'
          return
        end

        restore = parameters.include?('animate') || parameters.include?('float')
        width = parameters[0].to_i
        len = screen.columns
        pos = screen.get_pos
        x, y = pos
        ### move instead of printing spaces, spaces would erase a picture already on this line
        if parameters.include? 'right'
          x += len-width
        elsif parameters.include? 'center'
          x += (len-width)/2
        end
        screen.set_pos x, y
        if screen.respond_to?(:image) # pdf output
          screen.image what, width, additional[:fname]
          _, bottom = screen.get_pos
          last = bottom
          erase = nil
        else
          data = png(what,width,additional[:fname])
          return if data.empty?
          ### the terminal scales the png to the width, which says how many lines it covers
          w, h = data[16,8].unpack('NN')
          cw, ch = cell_size
          bottom = y + (width * cw * h / (w * ch).to_f).ceil
          ### bottom is the line after the picture, erasing it would erase what is there (e.g. the footer)
          last = bottom - 1
          id = rand(1...2**31)
          ### a picture drawn at the same place as another one replaces it (e.g. for animations). only its placement
          ### goes, the terminal keeps the data so going back can show it again. clearing the screen (next slide)
          ### removes all pictures, so whatever was placed before that is not there to replace.
          covered = @@placed[[x, y]]
          covered = nil unless covered && covered[2] == screen.cleared
          ### all chunks in one write, a flush per chunk stutters, q=2 keeps the terminal from answering
          chunks = Base64.strict_encode64(data).scan(/.{1,4096}/)
          screen.print (covered ? "\e_Ga=d,d=i,i=#{covered[0]},q=2\e\\" : '') + chunks.each_with_index.map { |chunk,i|
            keys = i == 0 ? "a=T,f=100,i=#{id},c=#{width},C=1,q=2," : ''
            "\e_G#{keys}m=#{i < chunks.length-1 ? 1 : 0};#{chunk}\e\\"
          }.join
          @@placed[[x, y]] = [id, width, screen.cleared, covered]
          ### pictures are not part of the text, printing spaces does not erase them. bring back what it replaced.
          erase = lambda do
            screen.print "\e_Ga=d,d=I,i=#{id},q=2\e\\"
            if covered
              screen.set_pos x, y
              screen.print "\e_Ga=p,i=#{covered[0]},c=#{covered[1]},C=1,q=2\e\\"
            end
            @@placed[[x, y]] = covered
          end
        end
        if restore
          screen.set_pos *pos
        else
          screen.set_pos 0, bottom
        end
        ### the area the picture covers, so going back can erase exactly that
        [x, y, x+width-1, last, erase].compact
      end
    end
  end
end
