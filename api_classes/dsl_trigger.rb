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

#--
##########################################
# Subversion information
# $Id: dsl_trigger.rb 395 2012-05-18 03:49:48Z nelsonab $
# $Revision: 395 $
##########################################
#++

require "api_classes/api_dsl"

class Trigger < ZabbixAPI_Base
  action :create do
    parameters "2.4" do
      add "triggerid","description","expression","comments","error","flags",
      "lastchange","priority","state","status","templateid","type","url",
      "value","dependencies"
      requires "description","expression"
    end
  end

  action :get do
    parameters "1.3",
      'triggerids', "select_functions", "nodeids", "groupids", "templateids",
      "hostids", "itemids", "applicationids", "functions", "inherited", "templated", "monitored",
      "active", "maintenance", "withUnacknowledgedEvents", "withAcknowledgedEvents",
      "withLastEventUnacknowledged", "skipDependent", "editable", "lastChangeSince",
      "lastChangeTill", "filter", "group", "host", "only_true", "min_severity", "search",
      "startSearch", "excludeSearch", "searchWildcardsEnabled", "output", "expandData",
      "expandDescription", "select_groups", "select_hosts", "select_items", "select_dependencies",
      "countOutput", "groupOutput", "preservekeys", "sortfield", "sortorder", "limit"

    parameters "2.4" do
      add "triggerids","groupids","templateids","hostids","itemids",
      "applicationids","functions","group","host","inherited","templated",
      "monitored","active","maintenance","withUnacknowledgedEvents",
      "withAcknowledgedEvents","withLastEventUnacknowledged","skipDependent",
      "lastChangeSince","lastChangeTill","only_true","min_severity",
      "expandComment","expandDescription","expandExpression","selectGroups",
      "selectHosts","selectItems","selectFunctions","selectDependencies",
      "selectDiscoveryRule","selectLastEvent","filter","limitSelects",
      "sortfield","countOutput","editable","excludeSearch","limit","output",
      "preservekeys","search","searchByAny","searchWildcardsEnabled",
      "sortorder","startSearch"
      #deprecate "expandData"
    end
  end

  action :adddependencies do
    parameters "2.4" do
      add       "triggerid","dependsOnTriggerid"
      requires "triggerid","dependsOnTriggerid"
    end
  end

  action :update do
    parameters "2.4" do
      add       "triggerid","description","expression","comments","error","flags",
      "lastchange","priority","state","status","templateid","type","url",
      "value","dependencies"
      requires "description","expression"
    end
  end

  alias :addDependencies :adddependencies
end

Trigger.delete
Trigger.deleteDependencies
Trigger.exists

