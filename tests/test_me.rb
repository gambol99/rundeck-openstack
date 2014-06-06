#!/usr/bin/env ruby
#
#   Author: Rohith
#   Date: 2014-05-22 12:53:05 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','../lib')
require 'rundeck-openstack'
require 'pp'

options = {
  :config => './config.yaml'
}

deck = RunDeckOpenstack.load( options )
# step: perform a classify
puts deck.classify

