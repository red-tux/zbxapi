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

