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

pp zabbix.history.get({'itemids'=>[1234,5678]})
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
      requires "groups"
    end

    parameters "2.0" do
      inherit from "1.3"
      add "interfaces","macros"
      requires "interfaces"
    end

    parameters "2.4" do
      inherit from "2.0"
      add "hostid","available","description","disable_until","error",
          "errors_from","flags","inventory","ipmi_available","ipmi_disable_until",
          "ipmi_error","ipmi_errors_from","jmx_available","jmx_disable_until",
          "jmx_error","jmx_errors_from","maintenance_from","maintenance_status",
          "maintenance_type","maintenanceid","snmp_available",
          "snmp_disable_until","snmp_error","snmp_errors_from"
      remove "dns","ip","ipmi_ip","port","useip","useipmi"
      requires "host","groups","interfaces"
    endend
```

In the above example three sets of valid and required parameters are set up.
One for versions 1.3, 2.0 and 2.4 of the API.  The parameter list is
automatically chosen by the API library based on the version string returned
from the Zabbix server.  If no valid or required parameters are given, no
parameter checking is performed.  In addition the library will chose the
most recent parameter list if there is not one for the specific version
of the Zabbix server, for instance if the API library only knows about
1.3, 2.0 and 2.4 and you are connecting to a 2.2 server, it will use the
2.0 list.  If you connect to a 2.6 server, and no parameter list has been
defined for 2.6, the 2.4 parameter list will be used.

Sometimes it is useful to create an alias for a command.  One example may be 
to have a method name in all lower case, or an easier to remember name for an 
existing method.
```ruby
class Host < ZabbixAPI_Base
  action :massadd do
    parameters "2.4" do
      add "hosts","groups","interfaces","macros","templates"
      requires "hosts"
    end
  end

  action :massremove do
    parameters "2.4" do
      add "hostids","groupids","interfaces","macros","templateids",
      "templateids_clear"
      requires "hostids"
    end
  end

  api_alias :massAdd, :massadd
  alias massRemove massremove
end
```

The above example will create two new methods "massAdd" and "massRemove", both of which
map to their lower case variants.  It is worth noting that api_alias is a built in DSL
function and will in turn populate the internal list of aliased methods which is
available for introspection via the api.aliases method.  However the ruby keyword
"alias" is also available and works, but it will not populate the internal aliased
methods list.


The library also supports some introspection.  Below are some examples from irb:
```ruby

irb(main):004:0> zabbix.host.api_methods.sort
=> [:create, :delete, :exists, :get, :massadd, :massremove, :massupdate, :update]

irb(main):005:0> zabbix.host.valid_params(:create,"2.4").sort
=> ["available", "description", "disable_until", "error", "errors_from", "flags",
"host", "hostid", "interfaces", "ipmi_authtype", "ipmi_available",
"ipmi_disable_until", "ipmi_error", "ipmi_errors_from", "ipmi_ip", "ipmi_password",
"ipmi_port", "ipmi_privilege", "ipmi_username", "jmx_available", "jmx_disable_until",
"jmx_error", "jmx_errors_from", "macros", "maintenance_from", "maintenance_status",
"maintenance_type", "maintenanceid", "name", "proxy_hostid", "snmp_available",
"snmp_disable_until", "snmp_error", "snmp_errors_from", "status", "useipmi"]

irb(main):006:0> zabbix.host.required_params(:create,"2.2")
=> ["groups", "interfaces"]

irb(main):007:0> zabbix.host.required_params(:create,"2.4")
=> ["groups", "interfaces", "host"]

irb(main):006:0> zabbix.host.api_methods.sort
=> [:create, :delete, :exists, :get, :massadd, :massremove, :massupdate, :update]

irb(main):007:0> zabbix.host.api_aliases
=> {:massAdd=>:massadd, :massRemove=>:massremove, :massUpdate=>:massupdate}
```
