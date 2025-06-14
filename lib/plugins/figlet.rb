module Chimp
  module Plugin
    class FIGLET < Base
      def process(what,parameters,screen,additional)
        x = `figlet #{what}`
        x
      end
    end
  end
end
