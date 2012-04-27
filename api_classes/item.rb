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
    debug(8,:var=>options)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('item.create', options))
    return obj['result']
  end

  def update(options)
    debug(8,:var=>options)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('item.update', options))
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
