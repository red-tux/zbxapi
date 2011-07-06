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
# Class ZbxAPI_Sysmap
#
# Class encapsulating sysmap functions
#
# get			Not implemented
# cr	eate		Basic implementation
#
#******************************************************************************

class ZbxAPI_Sysmap < ZbxAPI_Sub
  def create(options={})
    debug(8, "Sysmap.create Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.create',options))
    return obj['result']
  end

  # Alias function for code written against 1.0 API
  def add(options={})
    puts "WARNING API Function Sysmap.add is deprecated and will be removed in the future without further warning"
    create(options)
  end

  def addelement(options={})
    debug(8, "Sysmap.addelement Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.addelement',options))
    return obj['result']
  end

  def addlink(options={})
    debug(8, "Sysmap.addlink Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.addlink',options))
    return obj['result']
  end

  def getseid(options={})
    debug(8, "Sysmap.getseid Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.getseid',options))
    return obj['result']
  end

  def addlinktrigger(options={})
    debug(8, "Sysmap.addlinktrigger Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('map.addlinktrigger',options))
    return obj['result']
  end
end
