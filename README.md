RunDesk Openstack
=================

The gem is a small integretion piece between Rundeck and Openstack. The gem is used to pull and generate the the instance definitions of one or more openstack clusters

An example use

    require 'rundeck-openstack'
    
    options = {
      :config   => './config.yaml',          # the location of the configuration file
      :template => './my_custom_template',   # if you wish to override the default template
    }
    
    deck = RunDeckOpenstack.load( options )
    # step: perform a classify
    puts deck.classify
    

An example configuration

    ---
    openstack:
      - name: qa
        username: admin
        tenant: admin
        api_key: xxxxxxx
        auth_url: http://horizon.qa.xxxxx.com:5000/v2.0/tokens 
      - name: prod
        username: admin
        tenant: admin
        api_key: xxxxxxx
        auth_url: http://horizon.prod.xxxxx.com:5000/v2.0/tokens 
    tags:
      '.*':
        - openstack
      '^wiki.*': 
        - web 
        - web_server
      '^qa[0-9]{3}-[a-z0-9]{3}':
        - qa_server
        - web
    templates:
      - name: resourceyaml
        template: |
          ---
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
