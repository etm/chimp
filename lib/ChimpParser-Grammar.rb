require_relative 'ChimpParser'

module Chimp
  class Parser

    class SimpleGrammar < Grammar
      #### Patterns ####
      #### Name of pattern has to be the first parameter to pattern ####
      #### According to the names the methods are selected ####

      P_SLIDES      = Pattern.new("P_SLIDES",      /---+.*?(\z|\n)|\A/,      /^(?=---+)|\z/)
      P_WHAT        = Pattern.new("P_WHAT",        /^#\s*what:\s*/,                     /[\t ]*(\n|\z)/)
      P_INCREMENTAL = Pattern.new("P_INCREMENTAL", /\+\+\++.*?(\z|\n([\t ]*\n)*)|\A/,   /^(?=\+\+\++)|\z/)
      P_INCLUDE     = Pattern.new("P_INCLUDE",     /^%%([a-z0-9_]+,)*[a-z0-9_]+[\t ]+/, /[\t ]*(\n|\z)/)
      P_RANGE       = Pattern.new("P_RANGE",       /^%%([a-z0-9_]+,)*[a-z0-9_]+[\t ]+/, /^%%[\t ]*(\n|\z)/)
      P_RED         = Pattern.new("P_RED",         /!!/,                                /!!/)
      P_BLUE        = Pattern.new("P_BLUE",        /''/,                                /''/)
      P_STRONG      = Pattern.new("P_STRONG",      /'''/,                               /'''/)

      #### Grammar ####
      #### ROOT must exist and holds the main first level patterns ####
      #### G + patternname is selected to look nested patterns ####
      #### If G + patternname not exists, [] is assumend ####

      ROOT           = [ P_WHAT, P_SLIDES ]
      GP_SLIDES      = [ P_INCREMENTAL ]
      GP_INCREMENTAL = [ P_RANGE, P_INCLUDE, P_STRONG, P_RED, P_BLUE ]
      GP_RANGE       = [ P_STRONG, P_RED, P_BLUE ]
      GP_RED         = [ P_STRONG ]
      GP_BLUE        = [ P_STRONG ]
      GP_STRONG      = [ P_RED, P_BLUE]

      ### Optional functions called when a pattern occurs (m + patternname) ####
      def mP_INCLUDE(ts,ti,te)
        @tree.last.data = {}
        @tree.last.data[:name] = ts[2..-1].split(',')[0].strip
        @tree.last.data[:parameters] = ts[2..-1].split(',')[1]&.strip
        @tree.last.data[:additional] = @parameters
        @tree.last.data[:what] = ti.lstrip
        ''
      end
      def mP_RANGE(ts,ti,te)
        @tree.last.data = {}
        @tree.last.data[:name] = ts[2..-1].strip.split(',')[0].strip
        @tree.last.data[:parameters] = ts[2..-1].split(',')[1]&.strip
        @tree.last.data[:what] = ti.lstrip
        ''
      end
      def mP_WHAT(ts,ti,te)
        @tree.last.data = ti
        ''
      end
    end

  end
end
