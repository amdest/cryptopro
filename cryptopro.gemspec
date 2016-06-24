# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'cryptopro/version'

Gem::Specification.new do |s|
  s.name        = 'cryptopro'
  s.version     = Cryptopro::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = %w(divineforest ezubairov)
  s.email       = 'clowndesu@gmail.com'
  s.homepage    = 'http://github.com/ezubairov/cryptopro'
  s.summary     = %q{CryptoPro ruby-wrapper for linux and some various EDS-related utilities}
  # s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = 'cryptopro'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency 'cocaine'
  s.add_dependency 'curb'
end
