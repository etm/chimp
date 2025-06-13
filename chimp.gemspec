Gem::Specification.new do |s|
  s.name             = "chimp"
  s.version          = "0.99"
  s.platform         = Gem::Platform::RUBY
  s.license          = "GPL-3.0-or-later"
  s.summary          = "CHIMP - Make a cheap impression. Present on the terminal"

  s.description      = "see https://github.com/etm/chimp"

  s.files            = Dir['{example/**/*,tools/**/*,lib/**/*,}'] + %w(LICENSE INSTALL.md Rakefile chimp.gemspec AUTHORS)
  s.require_path     = 'lib'
  s.extra_rdoc_files = ['README.md','INSTALL.md']
  s.bindir           = 'tools'
  s.executables      = ['chimp']

  s.required_ruby_version = '>=2.7.0'

  s.authors          = ['Juergen eTM Mangler']

  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'https://github.com/etm/chimp'

  s.add_runtime_dependency 'tty-screen', '~> 0.8'
  s.add_runtime_dependency 'pastel', '~> 0.8'
end
