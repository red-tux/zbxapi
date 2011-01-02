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
# $Id$
# $Revision$
##########################################
#++

#setup our search path or libraries
$: << File.expand_path(File.join(File.dirname(__FILE__), '.'))

require 'libs/zdebug'
require 'libs/api_exceptions.rb'
require 'uri'
#require 'net/http'
require 'net/https'
require 'rubygems'
require 'json'



#------------------------------------------------------------------------------
#
# Class ZabbixAPI
#++
# Main Zabbix API class.
#
#------------------------------------------------------------------------------

class ZabbixAPI

  include ZDebug

  attr_accessor :method, :params, :debug_level, :auth

  #subordinate class
  attr_accessor :user # [User#new]
  #subordinate class
  attr_accessor :usergroup, :host, :item, :hostgroup, :application, :trigger, :sysmap, :history

  @id=0
  @auth=''
  @url=nil

  private
    @user_name=''
    @password=''


    class Redirect < Exception #:nodoc: all
    end

  public

  # The initialization routine for the Zabbix API class
  # * url is a string defining the url to connect to, it should only point to the base url for Zabbix, not the api directory
  # * debug_level is the default level to be used for debug messages
  # Upon successful initialization the class will be set up to allow a connection to the Zabbix server
  # A connection however will not have been made, to actually connect to the Zabbix server use the login method
  def initialize(url,debug_level=0)
    set_debug_level(debug_level)
    @orig_url=url  #save the original url
    @url=URI.parse(url+'/api_jsonrpc.php')
    @user = ZbxAPI_User.new(self)
    @usergroup = ZbxAPI_UserGroup.new(self)
    @host = ZbxAPI_Host.new(self)
    @item = ZbxAPI_Item.new(self)
    @hostgroup = ZbxAPI_HostGroup.new(self)
    @application = ZbxAPI_Application.new(self)
    @trigger = ZbxAPI_Trigger.new(self)
    @sysmap = ZbxAPI_Sysmap.new(self)
    @history = ZbxAPI_History.new(self)
    @id=0

    debug(6,"protocol: #{@url.scheme}, host: #{@url.host}")
    debug(6,"port: #{@url.port}, path: #{@url.path}")
    debug(6,"query: #{@url.query}, fragment: #{@url.fragment}")
  end

  #wraps the given information into the appropriate JSON object
  #* method is a string
  #* params is a hash of the parameters for the method to be called
  #Returns a hash representing a Zabbix API JSON call
  def json_obj(method,params={})
    obj =
      {
        'jsonrpc'=>'2.0',
        'method'=>method,
        'params'=>params,
        'auth'=>@auth,
        'id'=>@id
      }
    debug(10, "json_obj:  #{obj}")
    return obj.to_json
  end


  #Performs a log in to the Zabbix server
  #* _user_ is a string with the username
  #* _password_ is a string with the user''s password
  #* _save_ tells the method to save the login details in internal class variables or not
  #
  #Raises:
  #
  #* Zbx_API_ExeeptionBadAuth is raised when one of the following conditions is met
  #  1. no-string variables were passed in
  #  1. no username or password was passed in or saved from a previous login
  #  1. login details were rejected by the server
  #* ZbxAPI_ExceptionBadServerUrl
  #  1. There was a socket error
  #  1. The url used to create the class was bad
  #  1. The connection to the server was refused
  def login(user='',password='',save=true)
#    p user.class
#    p password.class
    if user.class!=String or password.class!=String
      raise ZbxAPI_ExceptionBadAuth.new,'Login called with non-string values'
    end
    if (user!='' and password!='') then
      l_user = user
      l_password = password
      if save then
        @user_name=user
        @password=password
      end
    elsif (@user_name!='' and @password!='') then
      l_user = @user_name
      l_password = @password
    else

    end

    begin
      result = do_request(json_obj('user.authenticate',{'user'=>l_user,'password'=>l_password}))
      @auth=result['result']

      #setup the version variables
      @major,@minor=do_request(json_obj('APIInfo.version',{}))['result'].split('.')
      @major=@major.to_i
      @minor=@minor.to_i

    rescue SocketError
      raise ZbxAPI_ExceptionBadServerUrl
    rescue JSON::ParserError
      raise ZbxAPI_ExceptionBadServerUrl
    rescue Errno::ECONNREFUSED
      raise ZbxAPI_ExceptionBadServerUrl
    rescue ZbxAPI_GeneralError => e
      if e.message["code"]==-32602
        raise ZbxAPI_ExceptionBadAuth,'Bad username and/or password'
      else
        raise e
      end
    end

  end

  # Tests to determine if the login information is still valid
  # returns: true if it is valid  or false if it is not.
  def test_login
    if @auth!='' then
      result = do_request(json_obj('user.checkauth',
        {'sessionid'=>@auth}))
      if !result['result'] then
        @auth=''
        return false  #auth hash bad
      end
        return true   #auth hash good
    else
      return false
    end
  end

  #Returns true if a login was performed
  def loggedin?
    !(@auth=='' or @auth.nil?)
  end

  #wrapper to loggedin?
  #returns nothing, raises the exception ZbxAPI_ExceptionBadAuth if loggedin? returns false
  def checkauth
    raise ZbxAPI_ExceptionBadAuth, 'Not logged in' if !loggedin?
  end

  #returns the version number for the API from the server
  def API_version(options={})
    return "#{@major}.#{@minor}"
  end

  # Provides raw access to the API via a small wrapper.
  # _method_ is the method to be called
  # _params_ are the parameters to be passed to the call
  # returns a hash of the results from the server
  def raw_api(method,params=nil)
    debug(6,method,"method")
    debug(6,params,"Parameters")

    checkauth
    checkversion(1,1)
    params={} if params==nil

    obj=do_request(json_obj(method,params))
    return obj['result']
  end

  # Function to test whether or not a function will work with the current API version of the server
  # If no options are presented the major and minor are assumed to be the minimum version
  # number suitable to run the function
  # Does not explicitly return anything, but raises ZbxAPI_ExceptionVersion if there is a problem
  def checkversion(major,minor,options=nil)
    caller[0]=~/`(.*?)'/
    caller_func=$1

    raise ZbxAPI_ExceptionVersion, "#{caller_func} requires API version #{major}.#{minor} or higher" if major>@major
    raise ZbxAPI_ExceptionVersion, "#{caller_func} requires API version #{major}.#{minor} or higher" if minor>@minor

  end

  #Sends JSON encoded string to server
  def do_request(json_obj)
    #puts json_obj
    redirects=0
    begin  # This is here for redirects
      http = Net::HTTP.new(@url.host, @url.port)
      http.use_ssl=true if @url.class==URI::HTTPS
      response = nil
#    http.set_debug_output($stderr)                                  #Uncomment to see low level HTTP debug
#    http.use_ssl = @url.scheme=='https' ? true : false
#    http.start do |http|
      headers={'Content-Type'=>'application/json-rpc',
        'User-Agent'=>'Zbx Ruby CLI'}
      debug(4,"Sending: #{json_obj}")
      response = http.post(@url.path, json_obj,headers)
      debug(4,"Response Code: #{response.code}")
      debug(4,response.body,"Response Body",5000)
      case response.code.to_i
        when 301
          puts "Redirecting to #{response['location']}"
          @url=URI.parse(response['location'])
				  raise Redirect
        when 500
          raise ZbxAPI_GeneralError.new("Zabbix server returned an internal error\n Call: #{json_obj}", :retry=>true)
      end
#    end

      @id+=1  # increment the ID value for the API call

      # check return code and throw exception for error checking
      resp = JSON.parse(response.body) #parse the JSON Object so we can use it
      if !resp["error"].nil?
        errcode=resp["error"]["code"].to_i
        case errcode
          when -32602 then
            raise ZbxAPI_ExceptionLoginPermission.new(resp["error"],:retry=>true)
          when -32500 then
            raise ZbxAPI_ExceptionPermissionError.new(resp["error"],:retry=>true)
          else
            puts "other error"
            raise ZbxAPI_GeneralError, resp["error"]
        end
      end

		  return resp

		rescue Redirect
		  redirects+=1
			retry if redirects<=5
			raise ZbxAPI_GeneralError, "Too many redirects"
    rescue NoMethodError
      raise ZbxAPI_GeneralError.new("Unable to connect to #{@url.host}", :retry=>false)
    end
  end

  private

  def setup_connection
    @http=Net::HTTP.new(@url.host, @url.port)
    http.use_ssl=true if @url.class==URI::HTTPS
  end
end

# Class: Zbx_API_Sub
# Wrapper class to ensure all class calls goes to the parent object not the
# currently instantiated object.
# Also ensures class specific variable sanity for global functions
class ZbxAPI_Sub < ZabbixAPI #:nodoc: all
  attr_accessor :parent

  def initialize(parent)
    @parent=parent
  end

  def checkauth
    @parent.checkauth
  end

  def checkversion(major,minor,options=nil)
    @parent.checkversion(major,minor,options)
  end

  def do_request(req)
    return @parent.do_request(req)
  end

  def json_obj(method, param)
    return @parent.json_obj(method, param)
  end

  def debug(level,param="",message=nil)
    @parent.debug(level,param,message)
  end
end

# Class ZbxAPI_User
#
# Class encapsulating User functions
#
# API Function          Status
# [get]                   Implemented, need error checking
# [authenticate]          Will not implement here, belongs in ZabbixAPI main class
# [checkauth]             Will not implement here, belongs in ZabbixAPI main class
# [getid]                 Implemented
# [create]               Implemented, need to test more to find fewest items
#                        needed, input value testing needed
# [update]
#
# [addmedia]
#
# [deletemedia]
#
# [updatemedia]
# [delete]    Implemented, checking of input values needed
#
# All functions expect a hash of options to add.
# If multiple users need to be manipulated it must be broken out into different calls

class ZbxAPI_User < ZbxAPI_Sub
  def get(options={})
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('user.get',options))
    return obj['result']
  end

  def getid(username)
    raise ZbxAPI_ExceptionArgumentError, "String argument expected" if username.class != String

    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('user.getid',{'alias'=>username}))
    return obj['result']
  end

  def create(options)
    checkauth
    checkversion(1,1)

    #Check input parameters

    raise ZbxAPI_ParameterError, "Missing 'name' argument", "User.create" if options["name"].nil?
    raise ZbxAPI_ParameterError, "Missing 'alias' argument", "User.create" if options["alias"].nil?
    raise ZbxAPI_ParameterError, "Missing 'passwd' argument", "User.create" if options["passwd"].nil?

    obj=do_request(json_obj('user.create',options))
    return obj['result']
  end

  # Alias function name for code written to work against 1.0 API
  # may be removed in future versions
  
  def add(options)
    puts "WARNING API Function User.add is deprecated and will be removed in the future without further warning"
    create(options)
  end

  def delete(userid)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('user.delete',[userid]))
    return obj['result']
  end

  def update(options)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('user.update',options))
    return obj['result']
  end

  # addmedia expects a hash of the following variables
  # userid, mediatypeid, sendto, severity, active, period
  def addmedia(options)
    debug(8, "User.addmedia Start")
    checkauth
    checkversion(1,1)

#    p options

    raise ZbxAPI_ParameterError, "Missing 'userid' argument", "User.addmedia" if options["userid"].nil?
    raise ZbxAPI_ParameterError, "Missing 'mediatypeid' argument", "User.addmedia" if options["mediatypeid"].nil?
    raise ZbxAPI_ParameterError, "Missing 'severity' argument", "User.addmedia" if options["severity"].nil?
    raise ZbxAPI_ParameterError, "Missing 'active' argument", "User.addmedia" if options["active"].nil?
    raise ZbxAPI_ParameterError, "Missing 'period' argument", "User.addmedia" if options["period"].nil?

    args = {}
    args["userid"]=options["userid"]
    args["medias"]={}
    args["medias"]["mediatypeid"]=options["mediatypeid"]
    args["medias"]["sendto"]=options["sendto"]
    args["medias"]["severity"]=options["severity"]
    args["medias"]["active"]=options["active"]
    args["medias"]["period"]=options["period"]

#    p args

    obj=do_request(json_obj('user.addMedia',args))
    return obj['result']
  end
end

#******************************************************************************
#
# Class ZbxAPI_Host
#
# Class encapsulating Host and template functions
#
# API Function          Status
# get                   Basic function implemented
# getid
# create                Basic function implemented 20091020
# update
# massupdate
# delete                Implimented
#
# template.create       implemented as host.create_template
# template.get          implemented as host.get_template
# template.delete       implemented as host.delete_template
#
#******************************************************************************

class ZbxAPI_Host < ZbxAPI_Sub
  def get(options={})
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('host.get',options))
    obj['result']
  end

  def get_template(options={})
    checkauth
    checkversion(1,3)

    obj=do_request(json_obj('template.get',options))
    obj['result']
  end

  def create(options={})
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('host.create',options))
    obj['result']
  end

  def create_template(options={})
    checkauth
    checkversion(1,3)

    obj=do_request(json_obj('template.create',options))
    obj['result']
  end

  # http://www.zabbix.com/documentation/1.8/api/objects/host#hostdelete
  #Accepts a single host id or an array  of host id's to be deleted
  def delete(ids)
    checkauth
    checkversion(1,3)

    obj=do_request(json_obj('host.delete',delete_helper("hostid",ids)))
    obj['result']
  end

  def delete_template(ids)
    checkauth
    checkversion(1,3)

    obj=do_request(json_obj('template.delete',delete_helper("templateid",ids)))
    obj['result']
  end

  private

  def delete_helper(id_type,ids)
    if ids.class==Fixnum
      ids=[ids]
    elsif ids.class==Array
      ids=ids
    else
      raise ZbxAPI_ParameterError, "ids parameter must be number or array"
    end

    ids.map do |id|
      {id_type=>id}
    end
  end

end

#******************************************************************************
#
# Class ZbxAPI_Item
#
# Class encapsulating Item functions
#
# API Function          Status
# get                   Basic Function working
# getid                 Function implemented
# create                   Function implemented
# update
# delete                Function implemented  - need to add type checking to input
#
#******************************************************************************

class ZbxAPI_Item < ZbxAPI_Sub
  def get(options={})
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('item.get',options))
    return obj['result']
  end

  def getid(options)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('item.getid', options))
    return obj['result']
  end

  def create(options)
    debug(8,options)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('item.create', options))
    return obj['result']
  end

  # Alias function for code written against 1.0 API
  def add(options)
    puts "WARNING API Function Item.add is deprecated and will be removed in the future without further warning"
    create(options)
  end

  def delete(ids)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('item.delete', ids))
    return obj['result']
  end
end

#******************************************************************************
#
# Class ZbxAPI_UserGroup
#
# Class encapsulating User Group functions
#
# API Function          Status
# get                   Basic function implemented
# getid
# create
# update
# updaterights
# addrights
# addusers
# removeusers
# delete
#
#******************************************************************************

class ZbxAPI_UserGroup < ZbxAPI_Sub
  def get(options={})
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('usergroup.get',options))
    return obj['result']
  end
end

#******************************************************************************
#
# Class ZbxAPI_HostGroup
#
# Class encapsulating User Group functions
#
# API Function          Status
# get                   Basic function implemented
# getid
# create
# update
# delete
# addhosts
# removehost
# addgroupstohost
# updategroupstohost
#
#******************************************************************************

class ZbxAPI_HostGroup < ZbxAPI_Sub
  def create(options={})
    debug(8, "HostGroup.create Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('hostgroup.create',options))
    return obj['result']
  end

  # alias function for code written against 1.0 API
  def add(options={})
    puts "WARNING API Function HostGroup.add is deprecated and will be removed in the future without further warning"
    create(options)
  end

  def get(options={})
    debug(8, "HostGroup.get Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('hostgroup.get',options))
    return obj['result']
  end

  def getId(name)
    puts "WARNING API Function HostGroup.getId is deprecated and will be removed in the future without further warning"
    getObjects(name)
  end

  def getObjects(name)
    debug(8, "HostGroup.getId Start")
    checkauth
    checkversion(1,1)

    begin
      if name.class==String
        do_request(json_obj('hostgroup.getObjects',{"name"=>name}))['result']
      elsif name.class==Array
        valid = name.map {|item| item.class==String ? nil : false}  # create a validation array of nils or false
        valid.compact!  # remove nils
        raise ZbxAPI_ParameterError, "Expected a string or an array of strings" if !valid.empty?

        results=[]
        name.each do |item|
          response=do_request(json_obj('hostgroup.getObjects',{"name"=>item}))
          response['result'].each {|result| results << result }  # Just in case the server returns an array
        end
        results
      else
        raise ZbxAPI_ParameterError, "Expected a string or an array of strings"
      end
    rescue ZbxAPI_GeneralError => e
      if e.message["code"]==-32602
        return 0
      else
        raise e
      end
    end
  end
end

#******************************************************************************

#
# Class ZbxAPI_Application
#
# Class encapsulating application functions
#
# API Function          Status
# get			Not implemented
# getById		Implemented
# getId			Not implemented
# create	              Not implemented
# update		Not implemented
# delete		Not implemented
#
#******************************************************************************


class ZbxAPI_Application < ZbxAPI_Sub
  def get(options={})
    debug(8, "Application.get Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('application.get',options))
    return obj['result']
  end

  def create(options={})
    debug(8, "Application.create Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('application.create',options))
    return obj['result']
  end

  # Alias function for code written against 1.0 API
  def add(options={})
    puts "WARNING API Function Application.add is deprecated and will be removed in the future without further warning"
    create(options)
  end

  def getid(options={})
    debug(8, "Application.getid Start")
    checkauth
    checkversion(1,1)

    begin
      obj=do_request(json_obj('application.getid',options))
    rescue ZbxAPI_GeneralError => e
      if e.message["code"]==-32400
        return 0
      else
        raise e
      end
    end
    return obj['result']
  end
end

#******************************************************************************
#
# Class ZbxAPI_Trigger
#
# Class encapsulating trigger functions
#
# get			Implemented
# getById		Not implemented
# getId			Not implemented
# create	              Implemented
# update		Not implemented
# delete		Not implemented
# addDependency		Not implemented
#
#******************************************************************************


class ZbxAPI_Trigger < ZbxAPI_Sub
  def get(options={})
    debug(8, "Trigger.get Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('trigger.get',options))
    return obj['result']
  end

  # Function name changed to reflect 1.1 API changes
  def create(options={})
    debug(8, "Trigger.create Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('trigger.create',options))
    return obj['result']
  end

  # Alias function for code written against 1.0 api
  def add(options={})
    puts "WARNING API Function Trigger.add is deprecated and will be removed in the future without further warning"
    create(options)
  end
end

#******************************************************************************
#
# Class ZbxAPI_Sysmap
#
# Class encapsulating sysmap functions
#
# get			Not implemented
# cr	eate		Basic implementation
#
#******************************************************************************

class ZbxAPI_Sysmap < ZbxAPI_Sub
  def create(options={})
    debug(8, "Sysmap.create Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.create',options))
    return obj['result']
  end

  # Alias function for code written against 1.0 API
  def add(options={})
    puts "WARNING API Function Sysmap.add is deprecated and will be removed in the future without further warning"
    create(options)
  end

  def addelement(options={})
    debug(8, "Sysmap.addelement Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.addelement',options))
    return obj['result']
  end

  def addlink(options={})
    debug(8, "Sysmap.addlink Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.addlink',options))
    return obj['result']
  end

  def getseid(options={})
    debug(8, "Sysmap.getseid Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.getseid',options))
    return obj['result']
  end

  def addlinktrigger(options={})
    debug(8, "Sysmap.addlinktrigger Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.addlinktrigger',options))
    return obj['result']
  end
end

#******************************************************************************
#
# Class ZbxAPI_History
#
# Class encapsulating history functions
#
# get
#
#******************************************************************************

class ZbxAPI_History

  def initialize(server)
    @server=server
  end

  #Get the history for an item.
  # itemids is a required option
  # example: get({"itemids"=>12345})
  def get(options)
    @server.checkauth
    @server.checkversion(1,3)

    raise ZbxAPI_ParameterError, "Missing 'itemid'", "History.get" if options["itemids"].nil?

    p obj=@server.raw_api("history.get",options)
    return obj['result']
  end

end


#******************************************************************************


if __FILE__ == $0

puts "Performing login"
zbx_api = ZabbixAPI.new('http://localhost')
zbx_api.login('apitest','test')

puts
puts "Getting user groups"
p zbx_api.usergroup.get

puts
puts "testing user.get"
zbx_api.debug_level=8
p zbx_api.user.get()
p zbx_api.user.get({"extendoutput"=>true})
zbx_api.debug_level=0


puts
puts "Getting by username, admin, number should be seen"
p zbx_api.user.getid('admin')
puts "Trying a bogus username"
p zbx_api.user.getid('bogus')

puts
puts "adding the user 'test' to Zabbix"
uid= zbx_api.user.create(
  [{ "name"=>"test",
    "alias"=>"testapiuser",
    "password"=>"test",
    "url"=>"",
    "autologin"=>0,
    "autologout"=>900,
    "theme"=>"default.css",
    "refresh"=>60,
    "rows_per_page"=>50,
    "lang"=>"en_GB",
    "type"=>3}])
p uid
puts "Deleting userid #{uid.keys[0]}"
p zbx_api.user.delete(uid.values[0])

puts
puts "getting items"
p zbx_api.item.get

puts
puts "getting items by host"
puts "host: #{hosts.values[0]}"
p items=zbx_api.item.get({'hostids'=>hosts.values[0]})

end
