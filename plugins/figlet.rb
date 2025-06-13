module Chimp
  module Plugin
    class FIGLET < Base
      def process(parameters)
        `figlet #{@what}`
      end
    end
  end
end
