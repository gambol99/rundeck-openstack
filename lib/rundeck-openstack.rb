#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-05-22 10:58:38 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
module RunDeckOpenstack
  ROOT = File.expand_path File.dirname __FILE__

  require "#{ROOT}/rundeck-openstack/version"

  autoload :Version,    "#{ROOT}/rundeck-openstack/version"
  autoload :Utils,      "#{ROOT}/rundeck-openstack/utils"
  autoload :Logger,     "#{ROOT}/rundeck-openstack/log"
  autoload :Loader,     "#{ROOT}/rundeck-openstack/loader"

  def self.version
    RunDeckOpenstack::VERSION
  end 

  def self.load options 
    RunDeckOpenstack::Loader::new( options )
  end
end
