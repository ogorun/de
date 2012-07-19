# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "de/version"

Gem::Specification.new do |s|
  s.name        = "de"
  s.version     = De::VERSION
  s.authors     = ["Olga Gorun"]
  s.email       = ["ogorun@quicklizard.com"]
  s.homepage    = ""
  s.summary     = %q{Dynamic Expression}
  s.description = %q{De (Dynamic Expression) module provides means to build and evaluate
dynamic expression of arbitrary complecity and operands/operators nature}

  s.rubyforge_project = "de"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rubytree', '~> 0.8.1'
  s.add_dependency 'activesupport', '>= 2.3.10'
  s.add_development_dependency 'rack-test'
end

