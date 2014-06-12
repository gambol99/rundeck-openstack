RunDesk Openstack
=================

The gem is a small integretion piece between Rundeck and Openstack. The gem is used to pull and generate a node resource file from one or more openstack clusters

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
          <<% @nodes.each do |node| %>
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

Tags
----

Tags simply provide a means of adding custom tags for rundeck to filter upon; The hostname is regexed and any node that matches inhierits those tags - alternative we can pull the tags from the openstack metadata

      tags:
      '.*':
        - openstack
      '^wiki.*': 
        - web 
        - web_server
      '^qa[0-9]{3}-[a-z0-9]{3}':
        - qa_server
        - web

