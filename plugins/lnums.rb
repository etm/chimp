module Chimp
  module Plugin
    class LNUMS < Base
      def process(parameter)
        i = 0
        parameter.strip.each_line.map do |l|
          i += 1
          ("%02i: " % i) + l
        end
      end
    end
  end  
end  
