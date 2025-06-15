module Chimp
  module Plugin
    class FIGLET < Base
      def process(what,parameters,screen,additional)
        if parameters.include? 'right'
          pos = screen.get_pos
          len = screen.columns
          `figlet #{what}`.each_line do |l|
            screen.print " " * (len-l.length+1) + l
          end
          screen.set_pos *pos
        elsif parameters.include? 'center'
          len = screen.columns
          `figlet #{what}`.each_line do |l|
            screen.print " " * ((len-l.length+1)/2) + l
          end
        else
          screen.print `figlet #{what}`
        end
      end
    end
  end
end
