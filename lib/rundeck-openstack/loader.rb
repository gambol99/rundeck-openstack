#
#   Author: Rohith
#   Date: 2014-05-22 11:07:10 +0100 (Thu, 22 May 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','./')
require 'fog'
require 'erb'
require 'yaml'
require 'config'
require 'pp'

module RunDeckOpenstack
class Loader

  include RunDeckOpenstack::Utils
  include RunDeckOpenstack::Utils::Logger

  attr_reader :config, :options, :nodes

  def initialize options
    raise ArgumentError, 'the options should be a hash'                unless options.is_a? Hash
    raise ArgumentError, 'you have not specify any configuration file' unless options.has_key? :config
    # step: validate the configuration file
    @config   = RunDeckOpenstack::Config::new options.config, options
    # step: set the options and config
    @cache   = {}
    @nodes   = []
    @options = options
  end

  def classify filter = {}
    begin
      # step: check if the configuration has changed and if so reload it
      @config = @config.reload if @config.changed?
      # step: specify the defaults
      %w(cluster hostname).each { |x| filter[x] = '.*' unless filter.has_key? x }
      # step: iterate and pull the nodes
      @nodes = []
      @config.openstack.each do |os|
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
      ERB.new( @config.erb, nil, '-' ).result( binding )
    rescue Exception => e
      puts 'classify: we have encountered an error: %s' % [ e.message ]
      raise Exception, e.message
    end
  end

  def flush
    @cache = {}
  end

  def keys
    @cache.keys
  end

  private
  def openstack_connection credentials
    #debug 'openstack_connection: attemping to connect to openstack: %s' % [ credentials['auth_url'] ]
    @connection ||= ::Fog::Compute.new( :provider => :OpenStack,
      :openstack_auth_url   => credentials.auth_url,
      :openstack_api_key    => credentials.api_key,
      :openstack_username   => credentials.username,
      :openstack_tenant     => credentials.tenant
    )
    @connection
    #debug 'successfully connected to openstack, username: ' << credentials['username'] << ' auth: ' << credentials.auth_url
  end

  def retrieve_nodes openstack
    #debug 'retrieve_nodes: retrieving a list of the nodes from openstack: ' << openstack.auth_url
    # step: get a connection to openstack
    cache      = {}
    connection = openstack_connection openstack
    # step: retrieve the nodes
    nodes = []
    connection.servers.each do |instance|
      node = {
        'cluster'    => openstack['name'],
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
      if @config.tags
        @config.tags.keys.each do |regex|
          next unless node['hostname'] =~ /#{regex}/
          ( node['tags'] || [] ) << @config.tags[regex]
        end
      end
      # step: find the image
      image = connection.images.select  { |x| x.id == node['image_id'] }
      tenant = connection.tenants.select { |x| x if x.id == node['tenant_id'] }
      set( instance.image['id'], ( !image.empty? ) ? image.first.name : 'image_deleted' ) unless cached? instance.image['id']
      set( instance.tenant_id, ( !tenant.empty? ) ? tenant.first.name : 'tenant_deletet' ) unless cached? instance.tenant_id
      node['image']   = cached instance.image['id']
      node['tenant']  = cached instance.tenant_id
      nodes << node
    end
    nodes
  end

  def set key, value
    @cache[key] = value
  end

  def cached key
    @cache[key] || nil
  end

  def cached? key
    @cache.has_key? key
  end

end
end

