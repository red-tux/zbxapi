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
# Class ZbxAPI_Application
#
# Class encapsulating application functions
#
# API Function          Status
# get			Not implemented
# getById		Implemented
# getId			Not implemented
# create	              Not implemented
# update		Not implemented
# delete		Not implemented
#
#******************************************************************************


class ZbxAPI_Application < ZbxAPI_Sub
  def get(options={})
    debug(8, "Application.get Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('application.get',options))
    return obj['result']
  end

  def create(options={})
    debug(8, "Application.create Start")
    checkauth
    checkversion(1,1)

    obj=do_request(json_obj('application.create',options))
    return obj['result']
  end

  # Alias function for code written against 1.0 API
  def add(options={})
    puts "WARNING API Function Application.add is deprecated and will be removed in the future without further warning"
    create(options)
  end

  def getid(options={})
    debug(8, "Application.getid Start")
    checkauth
    checkversion(1,1)

    begin
      obj=do_request(json_obj('application.getid',options))
    rescue ZbxAPI_GeneralError => e
      if e.message["code"]==-32400
        return 0
      else
        raise e
      end
    end
    return obj['result']
  end
end
