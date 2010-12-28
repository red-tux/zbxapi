#GPL 2.0  http://www.gnu.org/licenses/gpl-2.0.html
#Zabbix CLI Tool and associated files
#Copyright (C) 2009,2010 Andrew Nelson nelsonab(at)red-tux(dot)net
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

##########################################
# Subversion information
# $Id: zabcon_exceptions.rb 181 2010-04-08 03:33:18Z nelsonab $
# $Revision: 181 $
##########################################

#------------------------------------------------------------------------------
#
# Class ZbxAP_ParameterError
#
# Exception class for parameter errors for Argument Processor calls.
#
#------------------------------------------------------------------------------

require 'libs/zdebug'

require 'singleton'
require 'parseconfig'

# This class is for storing global variables.  This is accomplished by inheriting
# the singleton class.  To use a global variable it must be registered and then
# if some part of the program needs to be notified of a change a notifier can
# be registered for that variable.
class GlobalsBase
  include Singleton
  include ZDebug

  def initialize
    @hash={}
    @callbacks={}
  end

  # overload the assignment operator
  def []=(key,val)
    debug(9,[key,val],"Entering []= (key,val)",nil,true)
    if val.nil?
      delete(key) if !@hash[key].nil?
    else
      if !@hash[key].nil? and (@hash[key].class==Fixnum or @hash[key].class==Bignum)
        @hash[key]=Integer(val)
      else
        @hash[key]=val
      end

      if !@callbacks[key].nil?
         @callbacks[key].each {|proc|
           proc.call(@hash[key])  #use the value stored in the hash should there have been a conversion
         }
      end
    end
  end

  # overload the array operator
  def [](key)
    debug(9,key,"Entering [] (key)",nil,true)
    if @hash[key].nil?
      return nil
    else
      return @hash[key]
    end
  end

  def delete(key)
    @hash.delete(key)
  end

  def empty?
    return @hash.empty?
  end

  def each
    @hash.each {|k,v| yield k,v }
  end

  # Register a function to be called when the value of key changes.
  def register_notifier(key,proc)
    debug(9,[key,proc],"Entering register_notifier (key,proc)")
    if @callbacks[key].nil?
      @callbacks[key]=[proc]
    else
      @callbacks[key]<<proc
    end
  end
end

class GlobalVars < GlobalsBase

  def initialize
    super()
  end

end

class EnvVars < GlobalsBase

  def initialize
    super()
  end

  #overrides is a hash of options which will override what is found in the config file.
  #useful for command line options.
  #if there is a hash called "config_file" this will override the default config file.
  def load_config(overrides={})
    begin
      config_file = overrides["config_file"].nil? ? self["config_file"] : overrides["config_file"]
      config = overrides["load_config"]==false ?   # nil != false
      {} : ParseConfig.new(config_file).params
      # If we are not loading the config use an empty hash
    rescue Errno::EACCES
      if !(config_file=="zabcon.conf" and !File::exists?(config_file))
        puts "Unable to access configuration file: #{config_file}"
      end
      config={}
    end

    config.merge!(overrides)  # merge the two option sets together but give precedence
                              # to command line options

    config.each_pair { |k,v|
      self[k]=v
    }


#    debug(6,params)
#
#    #Setup a local OpenStruct to copy potentially passed in OpenStruct
#    #rather than query every time weather or not params is an OpenStruct
#    localoptions=OpenStruct.new
#
#    env=EnvVars.instance  # Instantiate the global EnvVars
#
#    if params.nil? or params.empty?  # nil or empty, use conffile
#      fname=@conffile
#    elsif params.class==OpenStruct   # use OpenStruct value or conffile
#      if params.configfile.nil?
#        fname=@conffile
#      else
#        fname=params.configfile
#        localoptions=params  # Since we have an OpenStruct passed in let's setup
#                             # our local OpenStruct variable for use later
#      end
#    elsif params.class==Hash  # use Hash[:filename] or raise an exception
#      if params[:filename].nil?
#        raise ZabconError.new("Expected a hash with the key 'filename'")
#      else
#        fname=params[:filename]
#      end
#    else  # If we get here something went wrong.
#      raise ZabconError.new("OH NO!!!  Received something unexpected in do_load_config.  Try again with debug level 6.")
#    end
#
#    begin
#      config=ParseConfig.new(fname).params
#      debug(1,config)
#
#      if !config["debug"].nil?
#        # If the command line option debug was not passed in use the config file
#        env["debug"]=config["debug"].to_i if localoptions.debug.nil?
#      end
#
#      if !config["server"].nil? and !config["username"].nil? and !config["password"].nil? then
#        do_login({:server=>config["server"], :username=>config["username"],:password=>config["password"]})
#      else
#        puts "Missing one of the following, server, username or password or bad syntax"
#      end
#
#      if !config["lines"].nil?
#        env["sheight"]=config["lines"].to_i
#      end
#
#      if !config["language"].nil?
#        env["language"]=config["language"]
#      end
#
#    rescue Errno::EACCES
#      puts "Unable to open file #{fname}"
#    rescue ZbxAPI_GeneralError => e
#      puts "An error was received from the Zabbix server"
#      if e.message.class==Hash
#        puts "Error code: #{e.message["code"]}"
#        puts "Error message: #{e.message["message"]}"
#        puts "Error data: #{e.message["data"]}"
#        retry
#      else
#        puts "Error: #{e.message}"
#        e.attempt_retry
#      end
#    end
  end


end
