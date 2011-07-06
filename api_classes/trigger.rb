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

require "subclass_base"

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
