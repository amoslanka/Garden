# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "garden/version"

Gem::Specification.new do |s|
  s.name        = "garden"
  s.version     = Garden::VERSION
  s.authors     = ["amoslanka"]
  s.email       = ["amoslanka@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{A utility for using different seed formats in your ActiveRecord database. }
  s.description = %q{Allows you to organize your seeds in different formats. Typical seeds.rb, yaml fixtures, and a variety of spreadsheet formats. }

  s.rubyforge_project = "garden"

  s.add_dependency 'spreadsheet'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
