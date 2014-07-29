#
#   Author: Rohith
#   Date: 2014-05-22 12:16:53 +0100 (Thu, 22 May 2014)
#
#  vim:ts=4:sw=4:et
#
require 'yaml'

module RunDeckOpenstack
  class Config
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
    attr_reader :config

    def initialize filename, options
      # step: check we have all the options
      @config   = validate_configuration filename, options
      @options  = options
      @filename = filename
    end

    def changed?
      ( @modified < File.mtime( @filename ) ) ? true : false
    end

    def reload
      @config = validate_configuration @filename, @options
    end

    def [](key)
      @config[key]
    end

    private
    def validate_configuration filename = @filename, options = @options
      # step: get the modified time
      @modified = File.mtime filename
      # step: read in the configution file
      config = YAML.load(File.read(filename))
      # step: check we have erveything we need
      raise ArgumentError, 'the configuration does not contain the openstack config' unless config['openstack']
      raise ArgumentError, 'the openstack field should be an array'                  unless config['openstack'].is_a? Array
      # step: we have to make sure we have 0.{username,api_key,auth_uri}
      config['openstack'].each do |os|
        raise ArgumentError, 'the credentials for a openstack cluster must have a name field' unless os.has_key? 'name'
        %w(username tenant api_key auth_url).each do |x|
          unless os.has_key? x
            raise ArgumentError, 'the credentials are incomplete, you must have the %s field for %s' % [ x, os['name'] ]
          end
        end
      end
      # step: lets validate templates or inject the default one
      config['erb'] = config['template'] || Default_Template
      config
    end
  end
end
