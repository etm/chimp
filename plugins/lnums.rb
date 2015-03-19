module Chimp
  module Plugin
    class LNUMS < Base
      def process(parameters)
        i = 0
        @what.each_line.map do |l|
          i += 1
          ("%02i: " % i) + l
        end.join('')
      end
    end
  end  
end  
