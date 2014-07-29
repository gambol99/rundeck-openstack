#
#   Author: Rohith
#   Date: 2014-05-22 11:07:10 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','./')
require 'fog'
require 'erb'
require 'config'

module RunDeckOpenstack
  class Loader
    include RunDeckOpenstack::Utils

    attr_reader :config, :options, :nodes

    def initialize app_options
      # step: validate the configuration file
      @options = app_options
      @nodes   = []
    end

    def classify filter = {}
      begin
        # step: check if the configuration has changed and if so reload it
        settings.reload if settings.changed?
        # step: specify the defaults
        filter['cluster'] ||= '.*'
        filter['hostname'] ||= '.*'
        # step: iterate and pull the nodes
        @nodes = []
        settings['openstack'].each do |os|
          # step: are we filtering our certain openstack clusters
          next unless os['name'] =~ /#{filter['cluster']}/
          # step: classifiy the nodes
          retrieve_nodes( os ).each do |node|
            # step: filter out anything we don't care about
            next unless node['hostname'] =~ /#{filter['hostname']}/
            @nodes << node
          end
        end
        # step: if requested, lets template the output
        ERB.new( settings['erb'], nil, '-' ).result( binding )
      rescue Exception => e
        puts 'classify: we have encountered an error: %s' % [ e.message ]
        raise Exception, e.message
      end
    end

    private
    def openstack_connection credentials
      debug 'openstack_connection: attemping to connect to openstack: %s' % [ credentials['auth_url'] ]
      connection = ::Fog::Compute.new( :provider => :OpenStack,
        :openstack_auth_url   => credentials['auth_url'],
        :openstack_api_key    => credentials['api_key'],
        :openstack_username   => credentials['username'],
        :openstack_tenant     => credentials['tenant']
      )
      debug 'successfully connected to openstack, username: ' << credentials['username'] << ' auth: ' << credentials['auth_url']
      connection
    end

    def retrieve_nodes credentials
      debug 'retrieve_nodes: retrieving a list of the nodes from openstack: ' << credentials['auth_url']
      # step: get a connection to openstack
      connection = openstack_connection( credentials )
      # step: retrieve the nodes
      nodes = []
      connection.servers.each do |instance|
        debug "retrieve_nodes: instance name: #{instance.name}, id: #{instance.id}"
        node = {
          'cluster'    => credentials['name'],
          'id'         => instance.id,
          'hostname'   => instance.name,
          'state'      => instance.state,
          'key_name'   => instance.key_name,
          'created'    => instance.created,
          'tags'       => instance.metadata.to_hash.values,
          'image_id'   => instance.image['id'],
          'tenant_id'  => instance.tenant_id,
          'user_id'    => instance.user_id,
          'hypervisor' => instance.os_ext_srv_attr_host,
          'flavor_id'  => instance.flavor['id'],
        }
        # step: lets add any tags from the config
        apply_node_tags node
        # step: find the image
        node['image'] = cached instance.image['id'] do
          get_image( instance.image['id'], connection ) || 'image_deleted'
        end
        node['tenant'] = cached instance.tenant_id do
          get_tenant( instance.tenant_id, connection ) || 'tenant_deleted'
        end
        nodes << node
      end
      nodes
    end

    def apply_node_tags node
      if settings['tags']
        settings['tags'].keys.each do |regex|
          next unless node['hostname'] =~ /#{regex}/
          ( node['tags'] || [] ) << settings['tags'][regex]
        end
      end
    end

    def get_image id, connection
      images = connection.images.select { |x| x.id == id }
      return ( !images.empty? ) ? images.first.name : nil
    end

    def get_tenant id, connection
      tenants = connection.tenants.select { |x| x if x.id == id }
      return ( !tenants.empty? ) ? tenants.first.name : nil
    end

    def cached key, &block
      if cache.has_key? key
        cache[key]
      else
        cache[key] = yield
      end
    end

    def cache
      @cache ||= {}
    end

    def settings options = @options
      @config ||= RunDeckOpenstack::Config::new options[:config], options
    end

    def options
      @options ||= default_options
    end

    def default_options
      {
        :config => "#{ENV['HOME']}/openstack.yaml"
      }
    end
  end
end

