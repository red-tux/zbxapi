require "api_classes/api_dsl"

class Host < ZabbixAPI_Base
  actions :update, :massAdd, :massUpdate, :massRemove

  action :get do
    #arg_processor "1.3" do |params|
    #  params["output"]="extend"
    #  params
    #end

    add_valid_params "1.3", ["nodeids","groupids","hostids","templateids",
                             "itemids","triggerids","graphids","proxyids","maintenanceids",
                             "dhostids","dserviceids","monitored_hosts","templated_hosts",
                             "proxy_hosts","with_items","with_monitored_items",
                             "with_historical_items","with_triggers","with_monitored_triggers",
                             "with_httptests","with_monitored_httptests","with_graphs",
                             "editable","filter","search","startSearch","excludeSearch",
                             "searchWildcardsEnabled","output","select_groups","selectParentTemplates",
                             "select_items","select_triggers","select_graphs","select_applications",
                             "select_macros","select_profile","countOutput","groupOutput",
                             "preservekeys","sortfield","sortorder","limit","extendoutput"]
  end

  action :exists do
    add_valid_params "1.3", ["nodeids","hostid","host"]
  end

  action :create do
    add_valid_params "1.3", ["host","port","status","useip",
        "dns","ip","proxy_hostid","useipmi","ipmi_ip","ipmi_port",
        "ipmi_authtype","ipmi_privilege","ipmi_username",
        "ipmi_password","groups","templates","interfaces"]
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
