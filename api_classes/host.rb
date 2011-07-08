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
# Class ZbxAPI_Host
#
# Class encapsulating Host and template functions
#
# API Function          Status
# get                   Basic function implemented
# getid
# create                Basic function implemented 20091020
# update
# massupdate
# delete                Implimented
#
# template.create       implemented as host.create_template
# template.get          implemented as host.get_template
# template.delete       implemented as host.delete_template
#
#******************************************************************************

class ZbxAPI_Host < ZbxAPI_Sub
  def get(options={})
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('host.get',options))
    obj['result']
  end

  def get_template(options={})
    checkauth
    checkversion(1,3)

    obj=do_request(json_obj('template.get',options))
    obj['result']
  end

  def create(options={})
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('host.create',options))
    obj['result']
  end

  def create_template(options={})
    checkauth
    checkversion(1,3)

    obj=do_request(json_obj('template.create',options))
    obj['result']
  end

  # http://www.zabbix.com/documentation/1.8/api/objects/host#hostdelete
  #Accepts a single host id or an array  of host id's to be deleted
  def delete(ids)
    checkauth
    checkversion(1,3)

    obj=do_request(json_obj('host.delete',delete_helper("hostid",ids)))
    obj['result']
  end

  def delete_template(ids)
    checkauth
    checkversion(1,3)

    obj=do_request(json_obj('template.delete',delete_helper("templateid",ids)))
    obj['result']
  end

  private

  def delete_helper(id_type,ids)
    if ids.class==Fixnum
      ids=[ids]
    elsif ids.class==Array
      ids=ids
    else
      raise ZbxAPI_ParameterError, "ids parameter must be number or array"
    end

    ids.map do |id|
      {id_type=>id}
    end
  end

end
