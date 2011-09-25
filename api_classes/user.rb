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
# $Id: zbxapi.rb 281 2011-04-06 18:10:16Z nelsonab $
# $Revision: 281 $
##########################################
#++

require "api_classes/subclass_base"

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
    debug(8, :msg=>"User.addmedia Start")
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
