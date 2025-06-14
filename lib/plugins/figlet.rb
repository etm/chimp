module Chimp
  module Plugin
    class FIGLET < Base
      def process(parameters,additional)
        x = `figlet #{@what}`
        x
      end
    end
  end
end
