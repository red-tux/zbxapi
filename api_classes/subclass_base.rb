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

# Class: Zbx_API_Sub
# Wrapper class to ensure all class calls goes to the parent object not the
# currently instantiated object.
# Also ensures class specific variable sanity for global functions
class ZbxAPI_Sub < ZabbixAPI #:nodoc: all
  attr_accessor :parent

  def initialize(parent)
    @parent=parent
  end

  def checkauth
    @parent.checkauth
  end

  def checkversion(major,minor,options=nil)
    @parent.checkversion(major,minor,options)
  end

  def do_request(req)
    return @parent.do_request(req)
  end

  def json_obj(method, param)
    return @parent.json_obj(method, param)
  end

  def debug(level,param="",message=nil)
    @parent.debug(level,param,message)
  end
end
