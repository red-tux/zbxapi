#License:: LGPL 2.1   http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
#Copyright:: Copyright (C) 2009,2010 Andrew Nelson nelsonab(at)red-tux(dot)net
#
#This library is free software; you can redistribute it and/or
#modify it under the terms of the GNU Lesser General Public
#License as published by the Free Software Foundation; either
#version 2.1 of the License, or (at your option) any later version.
#
#This library is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#Lesser General Public License for more details.
#
#You should have received a copy of the GNU Lesser General Public
#License along with this library; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

##########################################
# Subversion information
# $Id: api_exceptions.rb 337 2011-10-14 16:11:39Z nelsonab $
# $Revision: 337 $
##########################################

#------------------------------------------------------------------------------
#
# Class ZbxAP_ParameterError
#
# Exception class for parameter errors for Argument Processor calls.
#
#------------------------------------------------------------------------------

require 'zbxapi/zdebug'
require 'zbxapi/exceptions'

#------------------------------------------------------------------------------
#
# Class ZbxAPI_ExceptionBadAuth
#
# Exception class for bad authentication information
#
#------------------------------------------------------------------------------

class ZbxAPI_ExceptionBadAuth < ZError
end

#------------------------------------------------------------------------------
#
# Class ZbxAPI_ExceptionBadServerUrl
#
# Exception class for bad host url, also used for connection
# refused errors
#
#------------------------------------------------------------------------------

class ZbxAPI_ExceptionBadServerUrl < RuntimeError
end

#------------------------------------------------------------------------------
#
# Class ZbxAPI_ExceptionArgumentError
#
# Exception class for incorrect arguments to a method
#
#------------------------------------------------------------------------------

class ZbxAPI_ExceptionArgumentError < RuntimeError
end

#------------------------------------------------------------------------------
#
# Class ZbxAPI_ParameterError
#
# Exception class for parameter errors for API calls.
#
#------------------------------------------------------------------------------

class ZbxAPI_ParameterError < RuntimeError
end

#------------------------------------------------------------------------------
#
# Class ZbxAPI_ExceptionVersion
#
# Exception class for API version errors
#
#------------------------------------------------------------------------------

class ZbxAPI_ExceptionVersion < RuntimeError
end

#------------------------------------------------------------------------------
#
# Class ZbxAPI_ExceptionLoginPermission
#
# Exception class for lack of API login permission
#
#------------------------------------------------------------------------------

class ZbxAPI_ExceptionLoginPermission < ZError
  def initialize(message=nil, params={})
    super(message, params)
    @local_msg="This is also a general Zabbix API error number (Your error may not be a login error).\nTell the Zabbix devs to honor section 5.1 of the JSON-RPC 2.0 Spec."
  end
end

#------------------------------------------------------------------------------
#
# Class ZbxAPI_ExceptionPermissionError
#
# Exception class for general API permissions errors
#
#------------------------------------------------------------------------------

class ZbxAPI_ExceptionPermissionError < ZError
end

#------------------------------------------------------------------------------
#
# Class ZbxAPI_GeneralError
#
# Exception class for errors not encompassed in the above exceptions.
#
#------------------------------------------------------------------------------

class ZbxAPI_GeneralError < ZError
end
