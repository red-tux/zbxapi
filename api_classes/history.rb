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
# Class ZbxAPI_History
#
# Class encapsulating history functions
#
# get
#
#******************************************************************************

class ZbxAPI_History

  def initialize(server)
    @server=server
  end

  #Get the history for an item.
  # itemids is a required option
  # example: get({"itemids"=>12345})
  def get(options)
    @server.checkauth
    @server.checkversion(1,3)

    raise ZbxAPI_ParameterError, "Missing 'itemid'", "History.get" if options["itemids"].nil?

    p obj=@server.raw_api("history.get",options)
    return obj['result']
  end

end
