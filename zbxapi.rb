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

#TODO Create class to capture resultant data

class ZabbixAPI  #create a stub to be defined later
end

class ZbxAPI_Sub < ZabbixAPI  #create a stub to be defined later
end

#setup our search path or libraries
$: << File.expand_path(File.join(File.dirname(__FILE__), '.'))

require 'zbxapi/revision'
require 'zbxapi/zdebug'
require 'zbxapi/api_exceptions.rb'
require 'uri'
#require 'net/http'
require 'net/https'
require 'rubygems'
require 'json'
require 'pp'

require "api_classes/application"
require "api_classes/history"
require "api_classes/host"
require "api_classes/host_group"
require "api_classes/item"
require "api_classes/proxy"
require "api_classes/sysmap"
require "api_classes/trigger"
require "api_classes/user"
require "api_classes/user_group"



#------------------------------------------------------------------------------
#
# Class ZabbixAPI
#++
# Main Zabbix API class.
#
#------------------------------------------------------------------------------

class ZabbixAPI

  include ZDebug

  attr_accessor :method, :params, :debug_level, :auth, :verify_ssl

  #subordinate class
  attr_accessor :user # [User#new]
  #subordinate class
  attr_accessor :usergroup, :host, :item, :hostgroup, :application, :trigger, :sysmap, :history, :proxy
  @id=0
  @auth=''
  @url=nil
  @verify_ssl = true

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
    @proxy = ZbxAPI_Proxy.new(self)
    @item = ZbxAPI_Item.new(self)
    @hostgroup = ZbxAPI_HostGroup.new(self)
    @application = ZbxAPI_Application.new(self)
    @trigger = ZbxAPI_Trigger.new(self)
    @sysmap = ZbxAPI_Sysmap.new(self)
    @history = ZbxAPI_History.new(self)
    @id=0
    @proxy=nil

    debug(6,:msg=>"protocol: #{@url.scheme}, host: #{@url.host}")
    debug(6,:msg=>"port: #{@url.port}, path: #{@url.path}")
    debug(6,:msg=>"query: #{@url.query}, fragment: #{@url.fragment}")
  end

  def set_proxy(address,port,user=nil,password=nil)
    @proxy={:address=>address, :port=>port,
            :user=>user, :password=>password}
  end

  def self.get_version
    "#{ZBXAPI_VERSION}.#{ZBXAPI_REVISION}"
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
    debug(10, :msg=>"json_obj:  #{obj}")
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
    end

    #Somewhere in the 1.8.x cycle it was decided to do deprecate with user.authenticate
    #however it was not documented well, so we will try uer.login first, and fall
    #back to user.authenticate as user.login does not exist in 1.8.3
    login_methods=["user.login","user.authenticate"]

    begin
      result = do_request(json_obj(login_methods.first,{'user'=>l_user,'password'=>l_password}))
      @auth=result['result']

      #setup the version variables
      @major,@minor=do_request(json_obj('APIInfo.version',{}))['result'].split('.')
      @major=@major.to_i
      @minor=@minor.to_i
    rescue ZbxAPI_ExceptionLoginPermission => e
      login_methods.delete_at(0)
      if !login_methods.empty?
        retry
      else
        raise ZbxAPI_ExceptionBadAuth.new('Invalid User or Password',:error_code=>e.error_code)
      end
    rescue SocketError
      raise ZbxAPI_ExceptionBadServerUrl
    rescue JSON::ParserError
      raise ZbxAPI_ExceptionBadServerUrl
    rescue Errno::ECONNREFUSED
      raise ZbxAPI_ExceptionBadServerUrl
    rescue => e
      raise ZbxAPI_ExceptionBadAuth.new('General Login error, check host connectivity.')
    end
  end

  def logout
    do_request(json_obj('user.logout'))
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
    debug(6,:var=>method,:msg=>"method")
    debug(6,:var=>params,:msg=>"Parameters")

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
  #truncate_length determines how many characters at maximum should be displayed while debugging before
  #truncation should occur.
  def do_request(json_obj,truncate_length=5000)
    redirects=0
    begin  # This is here for redirects
      if @proxy
        http = Net::HTTP::Proxy(@proxy[:address],@proxy[:port],
              @proxy[:user],@proxy[:password]).new(@url.host,@url.port)
      else
        http = Net::HTTP.new(@url.host, @url.port)
      end
      http.use_ssl=true if @url.class==URI::HTTPS
      if ! @verify_ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @url.class==URI::HTTPS
      end
      response = nil
      headers={'Content-Type'=>'application/json-rpc',
        'User-Agent'=>'Zbx Ruby CLI'}
      debug(4,:msg=>"Sending: #{json_obj}")
      response = http.post(@url.path, json_obj,headers)
      debug(4,:msg=>"Response Code: #{response.code}")
      debug(4,:var=>response.body,:msg=>"Response Body",:truncate=>truncate_length)
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
            raise ZbxAPI_ExceptionLoginPermission.new(resp["error"],:error_code=>errcode,:retry=>true)
          when -32500 then
            raise ZbxAPI_ExceptionPermissionError.new(resp["error"],:error_code=>errcode,:retry=>true)
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
      raise ZbxAPI_GeneralError.new("Unable to connect to #{@url.host} : \"#{e}\"", :retry=>false)
    end
  end

  private

  def setup_connection
    @http=Net::HTTP.new(@url.host, @url.port)
    http.use_ssl=true if @url.class==URI::HTTPS
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
