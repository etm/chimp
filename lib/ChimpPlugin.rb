module Chimp
  module Plugin
    class Base
      def initialize; end
      def prepare(what,parameters,additional); end
      def process(what,parameters,screen,additional); end
    end
  end
end
