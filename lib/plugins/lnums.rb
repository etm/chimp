module Chimp
  module Plugin
    class LNUMS < Base
      def process(what,parameters,screen,additional)
        i = 0
        res = what.each_line.map do |l|
          i += 1
          ("%02i: " % i) + l
        end.join('')
        screen.print res
      end
    end
  end
end
