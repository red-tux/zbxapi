# -*- encoding: utf-8 -*-
# stub: zbxapi 0.3.3 ruby .

Gem::Specification.new do |s|
  s.name = "zbxapi"
  s.version = "0.3.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["."]
  s.authors = ["A. Nelson"]
  s.date = "2017-12-05"
  s.description = "Provides a straight forward interface to manipulate Zabbix servers using the Zabbix API."
  s.email = "nelsonab@red-tux.net"
  s.files = ["LICENSE", "api_classes/api_dsl.rb", "api_classes/dsl_action.rb", "api_classes/dsl_alert.rb", "api_classes/dsl_configuration.rb", "api_classes/dsl_dcheck.rb", "api_classes/dsl_dhost.rb", "api_classes/dsl_drule.rb", "api_classes/dsl_dservice.rb", "api_classes/dsl_event.rb", "api_classes/dsl_graph.rb", "api_classes/dsl_history.rb", "api_classes/dsl_host.rb", "api_classes/dsl_hostgroup.rb", "api_classes/dsl_hostinterface.rb", "api_classes/dsl_item.rb", "api_classes/dsl_mediatype.rb", "api_classes/dsl_proxy.rb", "api_classes/dsl_template.rb", "api_classes/dsl_trigger.rb", "api_classes/dsl_user.rb", "api_classes/dsl_usergroup.rb", "api_classes/dsl_usermacro.rb", "api_classes/dsl_usermedia.rb", "zbxapi.rb", "zbxapi/api_exceptions.rb", "zbxapi/exceptions.rb", "zbxapi/result.rb", "zbxapi/utils.rb", "zbxapi/zdebug.rb"]
  s.homepage = "https://github.com/red-tux/zbxapi"
  s.licenses = ["LGPL 2.1"]
  s.requirements = ["Requires json"]
  s.rubyforge_project = "zbxapi"
  s.rubygems_version = "2.5.2"
  s.summary = "Ruby wrapper to the Zabbix API"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<json>, [">= 0"])
    else
      s.add_dependency(%q<json>, [">= 0"])
    end
  else
    s.add_dependency(%q<json>, [">= 0"])
  end
end

