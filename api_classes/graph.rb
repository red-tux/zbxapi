# Title:: Zabbix API Ruby Library
# License:: LGPL 2.1   http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
# Copyright:: Copyright (C) 2009-2012 Andrew Nelson nelsonab(at)red-tux(dot)net
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

require "api_classes/subclass_base"

#******************************************************************************
#
# Class ZbxAPI_Item
#
# Class encapsulating Item functions
#
# API Function          Status
# get                   Function implemented
# create                Function implemented
# update		Function implemented
# delete                Function implemented  - need to add type checking to input
#
#******************************************************************************

class ZbxAPI_Graph < ZbxAPI_Sub
  def get(options={})
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('graph.get',options))
    return obj['result']
  end

  def create(options)
    debug(8,:var=>options)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('graph.create', options))
    return obj['result']
  end

  def update(options)
    debug(8,:var=>options)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('graph.update', options))
    return obj['result']
  end

  def delete(ids)
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('graph.delete', ids))
    return obj['result']
  end
end
