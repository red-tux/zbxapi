zbxapi The Zabbix API Interface in Ruby
=======================================
[![Gem Version](https://badge.fury.io/rb/zbxapi.png)](http://badge.fury.io/rb/zbxapi)

The ZbxAPI gem is designed to provide a straight forward interface to the 
Zabbix API in a Ruby friendly manner.

Initialzing a connection is pretty straight forward:
```ruby
require 'zbxapi'
require 'pp'

zabbix = ZabbixAPI.new("http://zabbix.example.com/", :verify_ssl => false, :http_timeout => 300 )
zabbix.login("api-user","api-pass")

pp zabbix.hitory.get({'itemids'=>[1234,5678]})
```

To get a list of valid objects, methods and parameters, use the api_info method.
```ruby
#Show all of the available objects
zabbix.api_info
["event", "graph", "user", "hostgroup", "usergroup","template", "proxy", "usermedia",
 "item", "history","trigger", "usermacro", "mediatype", "host"]

#Show all of the available methods for the host object
zabbix.api_info "host"
["update", "massAdd", "massUpdate", "massRemove", "get", "exists", "create", "delete"]

#Show all of the valid parameters for the host.create method for the most recent
#api version known
zabbix.api_info "host.create"
["host", "name", "port", "status", "useip", "dns", "ip", "proxy_hostid", "useipmi",
 "ipmi_ip", "ipmi_port", "ipmi_authtype", "ipmi_privilege", "ipmi_username",
 "ipmi_password", "groups", "templates", "interfaces"]

#Show the required parameters fo the host.create method for version 1.3 of the api
server.api_info "host.create", :params=>:required,:version=>"1.3"
 ["groups", "interfaces"]
 ```

Extending the API library is fairly straight forward as well.
1. Create a file in the api_classes directory with the format of dsl_<class_name>.rb
2. Inside the class file require the "api_dsl.rb" file
3. Inherit from the ZabbixAPI_Base class

All of the methods below will create methods for the Host object.  It is important to
note that the example for Host.update creates the method behind the scenes.
```ruby

class Host < ZabbixAPI_Base
  actions :massAdd, :massUpdate, :massRemove

  action :create do
  end
end

Host.update
```

To add a list of valid parameters to the Host.create method above use the following methods
```ruby
action :create do
  parameters "1.3" do
    add "host","name","port","status","useip","dns","ip","proxy_hostid",
         "useipmi","ipmi_ip","ipmi_port","ipmi_authtype","ipmi_privilege",
         "ipmi_username","ipmi_password","groups","templates"
    requires "groups","interfaces"
  end

  parameters "2.0" do
    inherit from "1.3"
    add "interfaces"
  end
end
```

In the above example two sets of valid and required parameters are set up.  One for version 1.3
of the API and the other for version 2.0 of the API.  The parameter list is automatically chosen
by the API library based on the version string returned from the Zabbix server.  If no valid or
required parameters are given, no parameter checking is performed.  In addition the library will
chose the most recent parameter list if there is not one for the specific version of the Zabbix
server, for instance if the API library only knows about 1.3 and 2.0 and you are connecting to a 2.2 server,
it will use the 2.0 list.