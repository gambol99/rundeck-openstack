#
#   Author: Rohith
#   Date: 2014-05-22 12:16:53 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
require 'yaml'

module RunDeckOpenstack
  class Config

    include RunDeckOpenstack::Utils

    Default_Template = <<-EOF
---
<% @nodes.each do |node| %>
<%= node['hostname'] %>:
  hostname: <%= node['hostname'] %>
  nodename: <%= node['hostname'].split('.').first %> 
  tags: '<%= node['tags'].concat( [ node['cluster'] ] ).join(', ') %>'
  username: rundeck 
  <% node.each_pair do |k,v| -%>
<%- next if k =~ /^(hostname|tags)$/ -%>
<%= k %>: <%= v %>
  <% end -%>
<% end -%>
EOF

    Config_Template = <<-EOF
---
# the openstack credentials
openstack:
  - name: qa
    username: USERNAME
    tenant: TENANT
    api_key: PASSWORD
    auth_url: KEYSTONE_URL:5000/v2.0/tokens
  - name: prod
    username: USERNAME
    tenant: TENANT
    api_key: PASSWORD
    auth_url: KEYSTONE_URL:5000/v2.0/tokens

# The tags regex the hostnames and if they match allow us to add extra tags
use_metatags: true      # you any metadata associated with the instance in the tags
tags:
  '.*':
    - openstack
  '^web[0-9]{3}-[a-z0-9]{3}': 
    - web 
  '^qa[0-9]{3}-[a-z0-9]{3}':
    - qa_server
    - web

templates:
  - name: resourceyaml
    template: |
      ---
      <%- @nodes.each do |node| -%>
      <%= node['hostname'] %>:
        description: <%= node['description'] %> 
        hostname: <%= node['hostname'] %> 
        nodename: <%= node['hostname'] %> 
        osArch: <%= node['os_arch'] %> 
        osFamily: <%= node['os_family'] %> 
        osName: <%= node['os_name'] %> 
        osVersion: <%= node['os_version'] %> 
        tags: '<%= node['cluster'] -%>, <%= node['tags'].join(\',\'') %>'
        username: '<%= node['owner'] %>'
      <%- end -%>
EOF

    attr_reader :config

    def initialize filename, options 
      # step: check we have all the options
      @config   = validate_configuration filename, options
      @options  = options
      @filename = filename
    end

    def self.config 
      Config_Template
    end

    def changed?
      ( @modified < File.mtime( @filename ) ) ? true : false 
    end

    def reload
      @config = validate_configuration @filename, @options
    end

    def template? name
      ( @config.templates.select { |x| x if x['name'] =~ /#{name}/ }.empty? ) ? false : true
    end

    def method_missing( m, *args, &block )
      @config[m] = args.first if !args.empty?
      return @config[m]       if @config.has_key?( m )  
      return @config[m.to_s]  if @config.has_key?( m.to_s )  
      nil
    end
    
    private
    def validate_configuration filename = @filename, options = @options
      # step: get the modified time
      @modified = File.mtime filename 
      # step: read in the configution file
      config = YAML.load_file( filename )
      # step: check we have erveything we need
      raise ArgumentError, 'the configuration does not contain the openstack config' unless config.openstack
      raise ArgumentError, 'the openstack field should be an array'                  unless config.openstack.is_a? Array
      # step: we have to make sure we have 0.{username,api_key,auth_uri}
      config.openstack.each do |os|
        raise ArgumentError, 'the credentials for a openstack cluster must have a name field' unless os.has_key? 'name'
        %w(username tenant api_key auth_url).each do |x|
          unless os.has_key? x 
            raise ArgumentError, 'the credentials are incomplete, you must have the %s field for %s' % [ x, os['name'] ]
          end
        end
      end
      # step: lets validate templates or inject the default one
      if !config.has_key? 'templates' or config['templates'].nil? and !options.template
        # we have no templates in config and the user has not specified any
        raise ArgumentError, 'there is no templates in configuration and you have not specified a custom template'
      end
      # step: do we have a custom template
      if options.template 
        validate_file options.template
        # step: load the template 
        config.erb File.read( options.template )
      else
        config.erb Default_Template
      end
      config
    end
  end
end
