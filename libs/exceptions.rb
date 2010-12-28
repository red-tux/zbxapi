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
# $Id$
# $Revision$
##########################################

require 'libs/zdebug'

#------------------------------------------------------------------------------
#
# Class ZError
#
# This is the superclass for all Zabcon and ZabbixAPI exceptions.
#
#------------------------------------------------------------------------------
class ZError < RuntimeError

  include ZDebug

  attr_reader :help_func, :message, :retry

  # list of valid params
  # :help_func, the help function with more information for the exception
  # : retry, is the exception eligable for retry?
  def initialize(message=nil, params=nil)
    debug(2,self.class,"Exception raised")
    debug(2,params,"params")
    raise "Exception not called correctly" if params.class!=Hash if !params.nil?
    params={} if params.nil?
    @help_func=params[:help_func]
    @message=message
    @local_msg="Error"
    @retry = params[:retry]
    super(message)
  end

  def show_message
    puts "** #{self.class}"
    if @message.nil? && @help_func.nil?
      puts "** #{@local_msg}"
      puts
    else
      if !@message.nil?
        @message.each_line {|line|
          puts "** #{line}"
        }
        puts
        puts "---" if !@help_func.nil?
      end
      @help_func.call if !@help_func.nil?
    end
  end

  #show the backtrace, if override is true it will be shown even if there is a help function
  def show_backtrace(override=false)
    if @help_func.nil? || override
      puts "Backtrace:"
      puts backtrace.join("\n")
    end
  end
  def retry?
    #the following may be worthy of a sig on "The Daily WTF", but this guarantees a boolean gets returned.
    #@retry is not guaranteed to be a boolean.
    if @retry
      return true
    else
      return false
    end
  end
end

class ParameterError < ZError
  def initialize(message=nil, params=nil)
    super(message, params)
    @local_msg="Parameter Error"
  end
end

#----------------------------------------------------------

class ParameterError_Invalid < ZError
  def initialize(message=nil, params=nil)
    super(message, params)
    @local_msg="Invalid Parameters"
  end
end

class ParameterError_Missing < ZError
  def initialize(message=nil, params=nil)
    super(message, params)
    @local_msg="Missing required parameters"
  end
end

#----------------------------------------------------------

class ParseError < ZError
  def initialize(message=nil, params=nil)
    super(message, params)
    @local_msg="Parse Error"
  end
end
