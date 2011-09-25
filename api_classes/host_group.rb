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
    debug(8, :msg=>"HostGroup.create Start")
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
    debug(8, :msg=>"HostGroup.get Start")
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
    debug(8, :msg=>"HostGroup.getId Start")
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
