# Title:: Zabbix API Ruby Library
# License:: LGPL 2.1   http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
# Copyright:: Copyright (C) 2009,2010 Andrew Nelson nelsonab(at)red-tux(dot)net
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

require "api_classes/api_dsl"

class Host < ZabbixAPI_Base
  actions :update, :massAdd, :massUpdate, :massRemove

  action :get do
    #arg_processor "1.3" do |params|
    #  params["output"]="extend"
    #  params
    #end

    parameters "1.3",
           "nodeids","groupids","hostids","templateids","itemids","triggerids",
           "graphids","proxyids","maintenanceids","dhostids","dserviceids",
           "monitored_hosts","templated_hosts","proxy_hosts","with_items",
           "with_monitored_items","with_historical_items","with_triggers",
           "with_monitored_triggers","with_httptests",
           "with_monitored_httptests","with_graphs","editable","filter",
           "search","startSearch","excludeSearch","searchWildcardsEnabled",
           "output","select_groups","selectParentTemplates","select_items",
           "select_triggers","select_graphs","select_applications",
           "selectInterfaces","select_macros","select_profile","countOutput",
           "groupOutput","preservekeys","sortfield","sortorder","limit",
           "extendoutput"

    parameters "2.0" do
      inherit from "1.3"
      add "selectGroups"
    end

    #parameters "3.0" do
    #  inherit from "2.0"
    #  remove "select_macros","preserve_keys","extendoutput"
    #  add "test_param"
    #  requires "test_param"
    #end
  end

  action :exists do
    parameters "1.3" do
      add "nodeids","hostid","host"
    end
  end

  action :create do
    parameters "1.3" do
      add "host","name","port","status","useip","dns","ip","proxy_hostid",
           "useipmi","ipmi_ip","ipmi_port","ipmi_authtype","ipmi_privilege",
           "ipmi_username","ipmi_password","groups","templates"
      requires "groups","interfaces"
    end

    parameters "2.0" do
      inherit from "1.3"
      add "interfaces","macros"
    end
  end

  action :delete do
    add_arg_processor "0" do |params|
      retval=nil
      if params.is_a?(Fixnum)
        retval=[{"hostid"=>params}]
      else
        retval=params
      end

      retval
    end
  end

end
