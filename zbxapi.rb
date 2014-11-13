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

#setup our search path or libraries
$: << File.expand_path(File.join(File.dirname(__FILE__), '.'))

#require 'zbxapi/revision'
require 'zbxapi/zdebug'
require 'zbxapi/api_exceptions.rb'
require 'zbxapi/result'
require 'uri'
require 'net/https'
require 'rubygems'
require 'json'

require "api_classes/api_dsl"

#Dynamicly load all API description files
dir=File.dirname(__FILE__)+"/api_classes/"
Dir[dir + 'dsl_*.rb'].each do |file|
   require dir+File.basename(file, File.extname(file))
end

def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end

#------------------------------------------------------------------------------
#
# Class ZabbixAPI
#++
# Main Zabbix API class.
#
#------------------------------------------------------------------------------

class ZabbixAPI

  include ZDebug

  attr_accessor :method, :params, :debug_level, :auth, :verify_ssl, :proxy_server

  class Redirect < Exception #:nodoc: all
  end

  public

  class << self
    public :define_method
  end

  # The initialization routine for the Zabbix API class
  # * url is a string defining the url to connect to, it should only point to the base url for Zabbix, not the api directory
  # * debug_level is the default level to be used for debug messages
  # Upon successful initialization the class will be set up to allow a connection to the Zabbix server
  # A connection however will not have been made, to actually connect to the Zabbix server use the login method
  #options:
  #Parameter        Default                Description
  #:debug           0                      Debug Level
  #:returntype      :result                Return the value of "result" from the json result
  #:verify_ssl      true                   Enable checking the SSL Cert
  def initialize(url,*args)
    options=args[0]
    options ||= {}
    if options.is_a?(Fixnum)
      warn "WARNING: Initialization has changed, backwards compatability is being used."
      warn "WARNING: Use ZabbixAPI.new(url,:debug=>n,:returntype=>:result) to have the"
      warn "WARNING: same capability as previous versions."
      warn "WARNING: This depreciated functionality will be removed in a future release"
      options={:debug=>0,:returntype=>:result}
    end

    #intialization of instance variables must happen inside of instantiation
    @id=0
    @auth=''
    @url=nil
    @verify_ssl=true
    @proxy_server=nil
    @custom_headers={}
    @user_name=''
    @password=''

    set_debug_level(options[:debug] || 0)
    @returntype=options[:returntype] || :result
    @orig_url=url  #save the original url
    @url=URI.parse(url+'/api_jsonrpc.php')

    if options.has_key?:verify_ssl
      @verify_ssl=options[:verify_ssl]
    else
      @verify_ssl = true
    end

    if options.has_key?:http_timeout
      @http_timeout=options[:http_timeout]
    else
      #if not set, default http read_timeout=60
      @http_timeout=nil
    end

    if options.has_key?:custom_headers
      @custom_headers = options[:custom_headers] unless options[:custom_headers].nil?
    else
      @custom_headers = {}
    end

    #Generate the list of sub objects dynamically, from all objects
    #derived from ZabbixAPI_Base
    objects=TRUE
    silence_warnings do
      objects=Object.constants.map do |i|
        obj=Object.const_get(i.intern)
        if obj.is_a?(Class) && ([ZabbixAPI_Base]-obj.ancestors).empty?
          obj
        else
          nil
        end
      end.compact-[ZabbixAPI_Base]
    end

    @objects={}

    objects.each do |i|
      i_s=i.to_s.downcase.intern
      @objects[i_s]=i.new(self)
      self.class.define_method(i_s) do
        instance_variable_get(:@objects)[i_s]
      end
    end

    @id=0

    debug(6,:msg=>"protocol: #{@url.scheme}, host: #{@url.host}")
    debug(6,:msg=>"port: #{@url.port}, path: #{@url.path}")
    debug(6,:msg=>"query: #{@url.query}, fragment: #{@url.fragment}")

    if block_given?
      yield(self)
    end
  end

  #Configure the information for the proxy server to be used to connect to the
  #Zabbix server
  def set_proxy(address,port,user=nil,password=nil)
    @proxy_server={:address=>address,:port=>port,
                   :user=>user, :password=>password}
    return self
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

    # https://www.zabbix.com/documentation/2.4/manual/api/reference/apiinfo/version
    # https://www.zabbix.com/documentation/2.4/manual/api/reference/user/login
    # Zabbix Doc(2.4): This method is available to unauthenticated
    #  users and must be called without the auth parameter
    #  in the JSON-RPC request.
    debug(4, :var => method,:msg => "Method:")
    obj.delete("auth") if ["apiinfo.version",
                           "user.login",
                          ].any? { |str| method =~ /#{str}/i }

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
      @major,@minor=do_request(json_obj('apiinfo.version',{}))['result'].split('.')
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
      raise ZbxAPI_ExceptionBadServerUrl.new("Socket Error")
    rescue JSON::ParserError
      raise ZbxAPI_ExceptionBadServerUrl
    rescue Errno::ECONNREFUSED
      raise ZbxAPI_ExceptionBadServerUrl
    rescue => e
      raise ZbxAPI_ExceptionBadAuth.new('General Login error, check host connectivity.')
    end

    return self
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

    raise ZbxAPI_ExceptionVersion, "#{caller_func} requires API version #{major}.#{minor} or higher" if major>@major or (minor>@minor and major>=@major)

  end

  #api_call
  #This is the main function for performing api requests
  #method is a string denoting the method to call
  #options is a hash of options to be passed to the function
  def api_call(method,options={})
    debug(6,:msg=>"Method",:var=>method)
    debug(6,:msg=>"Options",:var=>options)

    obj=json_obj(method,options)
    result=do_request(obj)
    if @returntype==:result
      result["result"]
    else
      result.merge!({:method=>method, :params=>options})
      @returntype.new(result)
    end
  end

  def api_info(request=:objects,*options)
    options = options[0] || {}
    version=options[:version] || nil
    request_type=options[:params] || :valid

    case request
      when :objects then
        @objects.keys.map { |k| k.to_s }
      else
        obj,meth=request.split(".")
        if meth then
          case request_type
            when :valid
              @objects[obj.intern].valid_params(meth.intern,version)
            when :required
              @objects[obj.intern].required_params(meth.intern,version)
          end
        else
          @objects[obj.intern].api_methods.map{ |m| m.to_s }
        end
    end
  end

  private

  #Select the http object to be used.
  def select_http_obj
    if @proxy_server
      http = Net::HTTP::Proxy(@proxy_server[:address],@proxy_server[:port],
            @proxy_server[:user],@proxy_server[:password]).new(@url.host,@url.port)
    else
      http = Net::HTTP.new(@url.host, @url.port)
    end
    http.use_ssl=true if @url.class==URI::HTTPS
    if !@verify_ssl
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @url.class==URI::HTTPS
    end
    http.read_timeout=@http_timeout unless @http_timeout.nil?

    http
  end

  #Sends JSON encoded string to server
  #truncate_length determines how many characters at maximum should be displayed while debugging before
  #truncation should occur.
  def do_request(json_obj,truncate_length=5000)
    redirects=0
    begin  # This is here for redirects
      http=select_http_obj
      response = nil
#    http.set_debug_output($stderr)                                  #Uncomment to see low level HTTP debug
      headers={
        'Content-Type'=>'application/json-rpc',
        'User-Agent'=>'Zbx Ruby CLI'
      }.merge(@custom_headers)

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
      raise ZbxAPI_GeneralError.new("Unable to connect to #{@url.host}: \"#{e}\"", :retry=>false)
    end
  end
end

#******************************************************************************


if __FILE__ == $0
  require 'pp'

  zbx=ZabbixAPI.new("http://zabbix.example.com/")
  #zbx.set_proxy("localhost",3128)
  zbx.login("user","password")
  pp zbx.host.get("output"=>"extend")

end
