require 'rake'
require 'rubygems/package_task'

spec = eval(File.read('chimp.gemspec'))
Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
  puts `ls -al pkg/*`
  `rm pkg/* -rf`
  `ln -sf #{pkg.name}.gem pkg/chimp.gem`
end

task :push => :gem do |r|
  `gem push pkg/chimp.gem`
end

task :install => :gem do |r|
  `gem install pkg/chimp.gem`
end

# task :release => :gem do |r|
#   GIT_COMMITTER_DATE="$(git show develop --format=%aD | head -1)" \
#   git tag -a "v1.7.0" develop -m "tag v1.7.0" \
#   && git push --tags origin develop \
#   && git --no-pager tag --list --format='%(refname)   %(taggerdate)'
# end
