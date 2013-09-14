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
# $Id: api_dsl.rb 409 2012-09-11 23:39:58Z nelsonab $
# $Revision: 409 $
##########################################
#++

require "zbxapi/zdebug"
require "zbxapi/exceptions"

class ZabbixAPI_Method
  include ZDebug

  class InvalidArity<RuntimeError
  end

  class AlreadyUsedError<RuntimeError
  end

  class InvalidMethodError<ZError
  end

  def initialize(apiclass,apimethod)
    @apiclass=apiclass
    @apimethod=apimethod
    @login_required=true
    @arg_processors={}  # {version=>block}
    @validparams={} # {version=>[valid parameters]}
    @requiredparams={}  # {version=>[required parameters]}
    @default=:default   # Which is the default version to use
    @method_names={}
    @method_names["0"]="#{@apiclass}.#{@apimethod}".downcase
    @deprecated=nil
    @invalidated=nil
  end

  def login_not_required
    @login_required=false
  end

  #Deprecate this function starting at API version ver
  #If msg is nil the following will be printed:
  #"#{method} is deprecated for API versions #{ver} and higher"
  # Where method is the current method name for the API
  def deprecate(ver,msg=nil)
    #Deprecate can only be called once
    raise AlreadyUsedError.new("Deprecate can only be used once per method") if @deprecated
    @deprecated={ver=>(msg || "") }
  end

  #Invalidate this function starting at API version ver
  #This will raise the ZabbixAPI_Method::InvalidMethod exception
  #If msg is nil the following string will be used in the exception:
  #"#{method} is invalid for API versions #{ver} and higher"
  # Where method is the current method name for the API
  def invalidate(ver,msg=nil)
    #Invalidate can only be called once
    raise AlreadyUsedError.new("Invalidate can only be used once per method") if @deprecated
    @invalidated={ver=>(msg || "") }
  end

  #Allows for the override of the API method to be called
  #The default method is version 0 which can be overridden
  def method_override(ver,name)
    @method_names[ver]=name
  end

  #add_arg_processor
  #Creates an argument processor suitable for versions starting at ver
  #ver is a string denoting the starting version number this argument processor should be used on
  #This method also needs a block to be passed.  The block
  def add_arg_processor(ver,&block)
    raise InvalidArity.new("Argument processor must accept one parameter") if block.arity !=1
    @arg_processors[ver]=block
    @default=ver
  end

  def get_arg_processor(ver)
    ver=get_version(ver,@arg_processors)
    return nil if ver.nil?
    @arg_processors[ver]
  end

  #calls the argument processor appropriate for ver
  #If no argument processor found, params are returned unchanged
  def call_arg_processor(ver,params={})
    processor=get_arg_processor(ver)
    if processor.nil?
      params
    else
      processor.call(params)
    end
  end

  def add_valid_params(ver,params)
    @validparams[ver]=params
  end

  def add_required_params(ver,params)
    @requiredparams[ver]=params
  end

  # Return the valid parameters for the method given version.
  # If version is nil, the highest version number available in the valid
  # parameters hash is used.
  # If ver is a version number, the closest version number in the valid
  # parameters hash which is less than or equal to is returned.
  # nil is returned is no valid parameters are found
  def get_valid_params(ver)
    ver=get_version(ver,@validparams)
    return nil if ver.nil?
    @validparams[ver]
  end

  def get_required_params(ver)
    ver=get_version(ver,@requiredparams)
    return nil if ver.nil?
    @requiredparams[ver]
  end

  def params_good?(server_version, params)
    debug(8,:msg=>"Server Version", :var=>server_version)
    var=params.is_a?(Hash) ? params.keys : params
    debug(8,:msg=>"Param keys", :var=>var)

    valid_params=get_valid_params(server_version)

    if valid_params  #continue to see if there's a required param
      raise ArgumentError.new("Named Arguments (Hash) expected for #{@apiclass}.#{@apimethod},"\
                              " '#{params.class}' received: #{params.inspect}") if !params.is_a?(Hash)
      args=params.keys.map{|key|key.to_s}

      invalid_args=args-valid_params
      debug(9,:msg=>"Invalid args",:var=>invalid_args)
      raise ZbxAPI_ParameterError.new("Invalid parameters #{invalid_args.inspect}") if !invalid_args.empty?
    end

    required_params=get_required_params(server_version)
#    ver=get_version(server_version,@requiredparams)

    return true if required_params.nil?
    required_args=required_params.reject { |i| i.class==Array }
    required_or_args=required_params.reject { |i| i.class!=Array }

    missing_args=[]
    missing_args=required_args-args

    required_or_args.delete_if do |i|
      count=i.length
      missing_args<<i if (i-args).count==count
    end

    debug(9,:msg=>"Required Params",:var=>required_params)
    debug(9,:msg=>"Missing params",:var=>missing_args)

    if !missing_args.empty?
      msg=missing_args.map do |i|
        if i.class==Array
          "(#{i.join(" | ")})"
        else
          i
        end
      end.join(", ")
      raise ZbxAPI_ParameterError.new("Missing required arguments: #{msg}")
    end
    true
  end

  #This is the function that does the actual APIcall.
  def do(server,params={})
    debug(7,:msg=>"Method Name",:var=>@method_names[@method_names.keys.sort.first])
    debug(7,:msg=>"Server",:var=>server)
    debug(7,:msg=>"Params",:var=>params)

    ver=get_version(server.API_version,@method_names)
    name=@method_names[ver]

    debug(8,:msg=>"Method Name used",:var=>name)

    if @invalidated
      ver=get_version(server.API_version,@invalidated)
      if ver
        msg=@invalidated.values.first.empty? ?
          "#{name} is invalid for api versions #{@invalidated.keys.first} and higher" : @invalidated.values.first
        raise InvalidMethodError.new(msg)
      end
    end

    if @deprecated
      ver=get_version(server.API_version,@deprecated)
      if ver
        msg=@deprecated.values.first.empty? ?
          "#{name} is deprecated for api versions #{@deprecated.keys.first} and higher" : @deprecated.values.first
        warn("Warning: #{msg}")
      end
    end

    debug(8,:msg=>"Params before arg processor",:var=>params)
    params=call_arg_processor(server.API_version,params)
    debug(7,:msg=>"Params after arg processor",:var=>params)
    params_good?(server.API_version,params)
    server.api_call(name,params)
  end

  #returns the version number closest to server which is less than
  #or equal to server
  #If no versions exist in hash, nil is returned
  def get_version(server,hash)
    return nil if hash.nil?
    if server
      #server=server.split(".").map{|i| i.to_i }
      keys=hash.keys.sort do |a,b|
        aa=a.split(".")
        bb=b.split(".")
        last_pos=((aa.length > bb.length) ? aa.length : bb.length)-1
        pos=0
        while aa[pos].to_i==bb[pos].to_i
          break if pos>=last_pos
          pos+=1
        end
        (aa[pos].to_i<=>bb[pos].to_i)
      end

      keys.delete_if do |k|
        kk=k.split(".")
        ss=server.split(".")
        last_pos=((kk.length > ss.length) ? ss.length : ss.length)-1
        pos=0
        while kk[pos].to_i<=ss[pos].to_i
          break if pos>=last_pos
          pos+=1
        end
        kk[pos].to_i>ss[pos].to_i
      end

      if keys.empty?
        return nil
      else
        return keys.last
      end
    else
      sorted=hash.keys.sort do |a,b|
        aa=a.split(".")
        bb=b.split(".")
        last_pos=((aa.length > bb.length) ? aa.length : bb.length)-1
        pos=0
        while aa[pos].to_i==bb[pos].to_i
          break if pos>=last_pos
          pos+=1
        end
        (aa[pos].to_i<=>bb[pos].to_i)
      end
      p sorted
      sorted.last
    end
  end


end

class ZabbixAPI_Base
  def initialize(server)
    @server=server
  end

  def api_methods
    self.class.api_methods.keys
  end

  def api_aliases
    self.class.api_aliases
  end

  def valid_params(sym,ver=nil)
    api_method=self.class.api_methods[sym]
    return nil if api_method.nil?
    api_method.get_valid_params(ver)
  end

  def self.method_missing(sym,&block)
    add(sym,&block)
  end

  def self.action(sym, &block)
    add(sym,&block)
  end

  def self.actions(*sym)
    sym.each {|s| add(s)}
  end

  def self.api_methods
    @api_methods
  end

  def self.api_aliases
    @api_aliases={} if @api_aliases.nil?
    @api_aliases
  end

  def self.alias(from,to)
    @api_aliases={} if @api_aliases.nil?
    @api_aliases[from]=to

    @api_methods[to]=@api_methods[from]

    define_method(to) do |params|
      self.class.api_methods[to].do(@server,params)
    end
  end

  def self.add(sym,&block)
    @api_methods={} if @api_methods.nil?
    @api_methods[sym]=ZabbixAPI_Method.new(self.to_s,sym.to_s)
    @api_methods[sym].instance_eval(&block) if !block.nil?

    #Create a method definition for the parameter in question.
    #params is not treated as an array, the splat operator
    #is there to allow for no parameters to be passed
    define_method(sym) do |*params|
      #The splat operator ensures we get an array, but we need
      #to test to ensure we receive one hash parameter
      if (params.length>1)
        raise ArgumentError.new("Hash or one argument expected for #{self.class}.#{sym.to_s}, received: #{params.inspect}")
      end
      self.class.api_methods[sym].do(@server,params.first||{})
    end
  end
end


