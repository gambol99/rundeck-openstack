#!/usr/bin/ruby
#
#   Author: Rohith
#   Date: 2014-05-22 16:48:00 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','lib/rundeck-openstack' )
require 'version'

Gem::Specification.new do |s|
    s.name        = "rundeck-openstack"
    s.version     = RunDeckOpenstack::VERSION
    s.platform    = Gem::Platform::RUBY
    s.date        = '2014-05-22'
    s.authors     = ["Rohith Jayawardene"]
    s.email       = 'gambol99@gmail.com'
    s.homepage    = 'http://rubygems.org/gems/rundeck-openstack'
    s.summary     = %q{Integration piece for node resources and rundesk with openstack clusters}
    s.description = %q{Integration piece for node resources and rundesk with openstack clusters}
    s.license     = 'MIT'
    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.add_dependency 'fog'
end
