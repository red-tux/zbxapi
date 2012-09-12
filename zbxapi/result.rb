#License:: GPL 2.0  http://www.gnu.org/licenses/gpl-2.0.html
#Copyright:: Copyright (C) 2009,2010 Andrew Nelson nelsonab(at)red-tux(dot)net
#
#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

##########################################
# Subversion information
# $Id: result.rb 395 2012-05-18 03:49:48Z nelsonab $
# $Revision: 395 $
##########################################

require 'zbxapi/zdebug'
require 'zbxapi/exceptions'
#require 'json'
require 'pp'

class ApiResult < Array
  include ZDebug

  class InvalidResult < ZError
  end

  class ErrorMessage <ZError
  end

  attr_accessor :fields, :params, :method_called

  def initialize(values={})
    raise InvalidResult.new if values["result"].nil?

    @params=values[:params]
    values.delete(:params) if values.key?(:params)
    @method_called=values[:method]
    values.delete(:method) if values.key?(:method)

    @id=values["id"]
    if values["result"].class!=Array
      super([values["result"]])
    else
      super(values["result"])
    end
    @fields=self.first.keys.map{|i| i.intern }
  end

  def method_missing(sym,*args)
    if @fields.index(sym)
       p @fields
       map {|i| i[sym.to_s]}
    else
      super(sym,*args)
    end
  end


  def [](*args)
    index=args[0]
    return self if index=="result"
    return self.first[index] if index.is_a?(String)
    super(*args)
  end

end