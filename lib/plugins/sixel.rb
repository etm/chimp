module Chimp
  module Plugin
    class SIXEL < Base
      def process(what,parameters,screen,additional)
        screen.print `img2sixel #{File.join(File.dirname(additional[:fname]),what)}`.strip
      end
    end
  end
end
