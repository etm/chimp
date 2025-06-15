require_relative 'ChimpParser'

module Chimp
  class Parser

    class SimpleGrammar < Grammar
      #### Patterns ####
      #### Name of pattern has to be the first parameter to pattern ####
      #### According to the names the methods are selected ####

      P_SLIDES      = Pattern.new("P_SLIDES",      /---+.*?(\z|\n)|\A/,                  /^(?=---+)|\z/)
      P_WHAT        = Pattern.new("P_WHAT",        /^#\s*what:\s*/,                      /[\t ]*(\n|\z)/)
      P_INCREMENTAL = Pattern.new("P_INCREMENTAL", /\+\+\++.*?(\z|\n)|\A/,               /^(?=\+\+\++)|\z/)
      P_RANGE       = Pattern.new("P_RANGE",       /^```([a-z0-9_]+,)*[a-z0-9_]+[\t ]*/, /^```[\t ]*(\n|\z)/)
      P_INCLUDE     = Pattern.new("P_INCLUDE",     /^```([a-z0-9_]+,)*[a-z0-9_]+[\t ]+/, /[\t ]*(\n|\z)/)
      P_CENTER      = Pattern.new("P_CENTER",     /^~~/,                                /[\t ]*(\n|\z)/)
      P_STRONG      = Pattern.new("P_STRONG",      /!!/,                                 /!!/)
      P_RED         = Pattern.new("P_RED",         /''/,                                 /''/)
      P_BLUE        = Pattern.new("P_BLUE",        /%%/,                                 /%%/)
      P_STRONGRED   = Pattern.new("P_STRONGRED",   /(!!''|''!!)/,                        /(''!!|!!'')/)
      P_STRONGBLUE  = Pattern.new("P_STRONGBLUE",  /(!!%%|%%!!)/,                        /(%%!!|!!%%)/)

      #### Grammar ####
      #### ROOT must exist and holds the main first level patterns ####
      #### G + patternname is selected to look up nested patterns ####
      #### If G + patternname not exists, [] is assumend ####

      ROOT           = [ P_WHAT, P_SLIDES ]
      GP_SLIDES      = [ P_INCREMENTAL ]
      GP_INCREMENTAL = [ P_CENTER, P_RANGE, P_INCLUDE, P_STRONGRED, P_STRONGBLUE, P_STRONG, P_RED, P_BLUE ]

      ### Optional functions called when a pattern occurs (m + patternname) ####
      def mP_CENTER(ts,ti,te)
        @tree.last.data = ti.length
        ti
      end

      def mP_INCLUDE(ts,ti,te)
        @tree.last.data = {}
        @tree.last.data[:name] = ts[3..-1].strip.split(',')[0]
        @tree.last.data[:parameters] = ts[3..-1].strip.split(',')[1..-1]
        @tree.last.data[:additional] = @parameters
        @tree.last.data[:what] = ti.lstrip
        ''
      end
      def mP_RANGE(ts,ti,te)
        @tree.last.data = {}
        @tree.last.data[:name] = ts[3..-1].strip.split(',')[0]
        @tree.last.data[:parameters] = ts[3..-1].strip.split(',')[1..-1]
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
