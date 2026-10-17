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
        pos = screen.get_pos if restore
        len = screen.columns
        ### move instead of printing spaces, spaces would erase a picture already on this line
        if parameters.include? 'right'
          x, y = screen.get_pos
          screen.set_pos x + len-parameters[0].to_i, y
        elsif parameters.include? 'center'
          x, y = screen.get_pos
          screen.set_pos x + (len-parameters[0].to_i)/2, y
        end
        if screen.respond_to?(:image) # pdf output
          screen.image what, parameters[0].to_i, additional[:fname]
        else
          screen.print sixel(what,parameters[0].to_i,additional[:fname])
        end
        if restore
          screen.set_pos *pos
        else
          x, y = screen.get_pos
          screen.set_pos 0,y
        end
      end
    end
  end
end
