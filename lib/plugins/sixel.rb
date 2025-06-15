module Chimp
  module Plugin
    class SIXEL < Base
      def process(what,parameters,screen,additional)
        if parameters[0] !~ /\d/
          screen.print 'Use ```sixel,NUM with NUM beeing the width if the picture in characters.'
          return
        end

        printit = if what =~ /\.svg$/
          "inkscape -D -d 300 --export-type=png #{File.join(File.dirname(additional[:fname]),what)} -o - | img2sixel -w #{parameters[0].to_i*10}"
        else
          "img2sixel -w #{parameters[0].to_i*10} #{File.join(File.dirname(additional[:fname]),what)}"
        end
        if parameters.include? 'right'
          pos = screen.get_pos
          len = screen.columns
          screen.print " " * (len-parameters[0].to_i)
          screen.print `#{printit}`
          screen.set_pos *pos
        elsif parameters.include? 'center'
          len = screen.columns
          screen.print " " * ((len-parameters[0].to_i)/2)
          screen.print `#{printit}`
          x, y = screen.get_pos
          screen.set_pos 0,y
        else
          screen.print `#{printit}`
        end
      end
    end
  end
end
