require 'fileutils'

module Chimp
  module Plugin
    class SIXEL < Base
      # converted images are cached in .PRESENTATIONNAME/ next to the presentation
      def cache_file(what,width,fname)
        dir = File.join(File.dirname(fname),'.' + File.basename(fname,'.*'))
        File.join(dir,"#{what.gsub('/','_')}.#{width}.sixel")
      end

      def sixel(what,width,fname)
        src = File.join(File.dirname(fname),what)
        cache = cache_file(what,width,fname)
        if File.exist?(cache) && File.exist?(src) && File.mtime(cache) >= File.mtime(src)
          return File.read(cache)
        end
        convert = if what =~ /\.svg$/
          "inkscape -D -d 300 --export-type=png #{src} -o - | img2sixel -w #{width*10}"
        else
          "img2sixel -w #{width*10} #{src}"
        end
        result = `#{convert}`
        if $?.success? && !result.empty?
          FileUtils.mkdir_p(File.dirname(cache))
          File.write(cache,result)
        end
        result
      end

      def prepare(what,parameters,additional)
        return if parameters[0] !~ /\d/
        sixel(what,parameters[0].to_i,additional[:fname])
      end

      def process(what,parameters,screen,additional)
        if parameters[0] !~ /\d/
          screen.print 'Use ```sixel,NUM with NUM beeing the width if the picture in characters.'
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
        else
          screen.print sixel(what,width,additional[:fname])
        end
        _, bottom = screen.get_pos
        if restore
          screen.set_pos *pos
        else
          screen.set_pos 0, bottom
        end
        ### the area the picture covers, so going back can erase exactly that
        [x, y, x+width-1, bottom]
      end
    end
  end
end
