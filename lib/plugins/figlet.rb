module Chimp
  module Plugin
    class FIGLET < Base
      def process(what,parameters,screen,additional)
        screen.print "\e[1m" if parameters.include? 'bold'
        font = parameters.include?('small') ? ' -f small' : ''
        if parameters.include? 'right'
          pos = screen.get_pos
          len = screen.columns
          `figlet#{font} #{what}`.each_line do |l|
            screen.print " " * (len-l.length+1) + l
          end
          screen.set_pos *pos
        elsif parameters.include? 'center'
          len = screen.columns
          `figlet#{font} #{what}`.each_line do |l|
            screen.print " " * ((len-l.length+1)/2) + l
          end
        else
          screen.print `figlet#{font} #{what}`
        end
        screen.print "\e[0m" if parameters.include? 'bold'
      end
    end
  end
end
