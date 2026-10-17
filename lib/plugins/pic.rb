require 'io/console'
require_relative 'sixel'
require_relative 'kitty'

module Chimp
  module Plugin
    class PIC < Base
      #### ask the terminal once: a kitty graphics query, then a device attributes query (4 means sixel),
      #### which every terminal answers, so we know when to stop waiting for the kitty answer
      def detect
        return ENV['CHIMP_PIC'].to_sym if %w{kitty sixel none}.include?(ENV['CHIMP_PIC'])
        return :none unless $stdin.tty? && $stdout.tty?
        res = ''
        $stdin.raw do
          $stdout << "\e_Gi=31,s=1,v=1,a=q,t=d,f=24;AAAA\e\\\e[c"
          $stdout.flush
          while IO.select([$stdin], nil, nil, 1) && (c = $stdin.getc)
            res << c
            break if res =~ /\e\[\?[\d;]*c/
          end
        end
        if res.include?("\e_Gi=31;OK")
          :kitty
        elsif res =~ /\e\[\?([\d;]*)c/ && $1.split(';').include?('4')
          :sixel
        else
          :none
        end
      rescue StandardError
        :none
      end

      def graphics
        @@graphics ||= detect
      end

      def delegate(screen=nil)
        ### the pdf does not care, both plugins hand the picture to it
        return SIXEL.new if screen.respond_to?(:image)
        case graphics
          when :kitty then KITTY.new
          when :sixel then SIXEL.new
        end
      end

      def prepare(what,parameters,additional)
        delegate&.prepare(what,parameters,additional)
      end

      def process(what,parameters,screen,additional)
        if parameters[0] !~ /\d/
          screen.print 'Use ```pic,NUM with NUM beeing the width if the picture in characters.'
          return
        end
        delegate(screen)&.process(what,parameters,screen,additional)
      end
    end
  end
end
