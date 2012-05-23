# -*- encoding: utf-8 -*-
require File.expand_path('../lib/routable/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "routable"
  s.version     = Routable::VERSION
  s.authors     = ["Clay Allsopp"]
  s.email       = ["clay.allsopp@gmail.com"]
  s.homepage    = "https://github.com/clayallsopp/Routable"
  s.summary     = "A RubyMotion UIViewController -> URL router"
  s.description = "A RubyMotion UIViewController -> URL router"

  s.files         = `git ls-files`.split($\)
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
end