module Chimp
  module Plugin
    class FIGLET < Base
      def process(parameters,additional)
        `figlet #{@what}`
      end
    end
  end
end
