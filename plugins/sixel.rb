module Chimp
  module Plugin
    class SIXEL < Base
      def process(parameters,additional)
        `img2sixel #{File.join(File.dirname(additional[:fname]),@what)}`
      end
    end
  end
end
