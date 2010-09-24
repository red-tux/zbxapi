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
# $Id$
# $Revision$
##########################################

path=File.expand_path(File.dirname(__FILE__) + "/../libs")+"/"

require path + '../zabbixapi'
require path + 'zdebug'
require path + 'zabcon_globals'

class ZbxCliServer

  include ZDebug

  attr_reader :server_url, :user, :password

  def initialize(server,user,password,debuglevel=0)
    @server_url=server
    @user=user
    @password=password
    @debuglevel=debuglevel
    # *Note* Do not rescue errors here, rescue in function that calls this block
    @server=ZabbixAPI.new(@server_url,@debuglevel)
    @server.login(@user, @password)
    GlobalVars.instance["auth"]=@server.auth
  end

  def debuglevel=(level)
    @server.debug_level=level
  end

  def login?
    !@server.nil?
  end

  def version
    @server.API_version
  end

  def reconnect
    @server.login(@user,@password)
  end

  def getuser(parameters)
    debug(6,parameters)

    result=@server.user.get(parameters)
    {:class=>:user, :result=>result}
  end

  def gethost(parameters)
    debug(6,parameters)

    result=@server.host.get(parameters)
    {:class=>:host, :result=>result}
  end

  def addhost(parameters)
    debug(6,parameters)
    result=@server.host.create(parameters)
    {:class=>:host, :message=>"The following host was created: #{result['hostids']}", :result=>result}
  end

  def deletehost(parameters)
    debug(6,parameters)
    result=@server.host.delete(parameters)
    {:class=>:host, :message=>"The following host(s) was/were deleted: #{result['hostids']}", :result=>result}
  end

  def getitem(parameters)
    debug(6,parameters)

    result=@server.item.get(parameters)
    {:class=>:item, :result=>result}
  end

  def additem(parameters)
    debug(6,parameters)
    {:class=>:item, :result=>@server.item.create(parameters)}
  end

  def deleteitem(parameters)
    debug(6,parameters)
    {:class=>:item, :result=>@server.item.delete(parameters)}
  end

  def adduser(parameters)
    debug(6,parameters)
    begin
      uid=@server.user.create(parameters)
      puts "Created userid: #{uid["userids"]}"
    rescue ZbxAPI_ParameterError => e
      puts "Add user failed, error: #{e.message}"
    end
  end

  def deleteuser(parameter)
    debug(6,parameter)
    id=0  #id to delete
#    if parameters.nil? then
#      puts "User id required"
#      return
#    end

    if !parameter["name"].nil?
      users=@server.user.get({"pattern"=>parameter["name"], "extendoutput"=>true})
      users.each { |user| id=user["userid"] if user["alias"]==parameter }
    else
      id=parameter["id"]
    end
    result=@server.user.delete(id)
    if !result.empty?
      puts "Deleted user id #{result["userids"]}"
    else
      puts "Error deleting #{parameter.to_a[0][1]}"
    end
  end

  def updateuser(parameters)
    debug(6,parameters)
    valid_parameters=['userid','name', 'surname', 'alias', 'passwd', 'url', 'autologin',
                      'autologout', 'lang', 'theme', 'refresh', 'rows_per_page', 'type',]
    if parameters.nil? or parameters["userid"].nil? then
      puts "Edit User requires arguments, valid fields are:"
      puts "name, surname, alias, passwd, url, autologin, autologout, lang, theme, refresh"
      puts "rows_per_page, type"
      puts "userid is a required field"
      puts "example:  edit user userid=<id> name=someone alias=username passwd=pass autologout=0"
      return false
    else
      p_keys = parameters.keys

      valid_parameters.each {|key| p_keys.delete(key)}
      if !p_keys.empty? then
        puts "Invalid items"
        p p_keys
        return false
      elsif parameters["userid"].nil?
        puts "Missing required userid statement."
      end
      p @server.user.update([parameters])
    end
  end

  def addusermedia(parameters)
    debug(6,parameters)
    valid_parameters=["userid", "mediatypeid", "sendto", "severity", "active", "period"]

    if parameters.nil? then
      puts "add usermedia requires arguments, valid fields are:"
      puts "userid, mediatypeid, sendto, severity, active, period"
      puts "example:  add usermedia userid=<id> mediatypeid=1 sendto=myemail@address.com severity=63 active=1 period=\"\""
    else

      p_keys = parameters.keys

      valid_parameters.each {|key| p_keys.delete(key)}
      if !p_keys.empty? then
        puts "Invalid items"
        p p_keys
        return false
      elsif parameters["userid"].nil?
        puts "Missing required userid statement."
      end
      begin
        @server.user.addmedia(parameters)
      rescue ZbxAPI_ParameterError => e
        puts e.message
      end
    end

  end

  def addhostgroup(parameters)
    debug(6,parameters)
    result = @server.hostgroup.create(parameters)
    {:class=>:hostgroup, :result=>result}
  end

  def gethostgroup(parameters)
    debug(6,parameters)

    result=@server.hostgroup.get(parameters)
    {:class=>:hostgroup, :result=>result}
  end

  def gethostgroupid(parameters)
    debug(6,parameters)
    result = @server.hostgroup.getObjects(parameters)
    {:class=>:hostgroupid, :result=>result}
  end

  def getapp(parameters)
    debug(6,parameters)

    result=@server.application.get(parameters)
    {:class=>:application, :result=>result}
  end

  def addapp(parameters)
    debug(6,parameters)
    result=@server.application.create(parameters)
    {:class=>:application, :result=>result}
  end

  def getappid(parameters)
    debug(6,parameters)
    result=@server.application.getid(parameters)
    {:class=>:application, :result=>result}
  end

  def gettrigger(parameters)
    debug(6,parameters)
    result=@server.trigger.get(parameters)
    {:class=>:trigger, :result=>result}
  end

  # addtrigger( { trigger1, trigger2, triggern } )
  # Only expression and description are mandatory.
  # { { expression, description, type, priority, status, comments, url }, { ...} }
  def addtrigger(parameters)
    debug(6,parameters)
    result=@server.trigger.create(parameters)
    {:class=>:trigger, :result=>result}
  end

  def addlink(parameters)
    debug(6,parameters)
    result=@server.sysmap.addlink(parameters)
    {:class=>:map, :result=>result}
  end

  def addsysmap(parameters)
    debug(6,parameters)
    result=@server.sysmap.create(parameters)
    {:class=>:map, :result=>result}
  end

  def addelementtosysmap(parameters)
    debug(6,parameters)
    result=@server.sysmap.addelement(parameters)
    {:class=>:map, :result=>result}
  end

  def getseid(parameters)
    debug(6,parameters)
    result=@server.sysmap.getseid(parameters)
    {:class=>:map, :result=>result}
  end

  def addlinktrigger(parameters)
    debug(6,parameters)
    result=@server.sysmap.addlinktrigger(parameters)
    {:class=>:map, :result=>result}
  end

  def raw_api(parameters)
    debug(6,parameters)
    result=@server.raw_api(parameters[:method],parameters[:params])
    {:class=>:raw, :result=>result}
  end

  def raw_json(parameters)
    debug(6,parameters)
    begin
      result=@server.do_request(parameters)
      {:class=>:raw, :result=>result["result"]}
    rescue ZbxAPI_GeneralError => e
      puts "An error was received from the Zabbix server"
      if e.message.class==Hash
        puts "Error code: #{e.message["code"]}"
        puts "Error message: #{e.message["message"]}"
        puts "Error data: #{e.message["data"]}"
      end
      puts "Origional text:"
      puts parameters
      puts
      return {:class=>:raw, :result=>nil}
    end
  end

end

##############################################
# Unit test
##############################################

if __FILE__ == $0
  zbxcliserver = ZbxCliServer.new("http://localhost/","apitest","test")   #Change as appropriate for platform

  p zbxcliserver.getuser(nil)
end
