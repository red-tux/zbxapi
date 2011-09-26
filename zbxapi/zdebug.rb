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

module ZDebug

  # Either set_debug_level or set_facility_debug_level must be called before
  # the debug functions can be used.
  def set_debug_level(level)   # sets the current debug level for printing messages
    @@debug_level=level

    # Create faciltiy_level if it's not created already
    @@facility_level= {} if !defined?(@@facility_level)
  end

  # facility is a symbol, level is an integer
  def set_facility_debug_level(facility,level)
    # Create faciltiy_level if it's not created already
    @@facility_level= {} if !defined?(@@facility_level)

    @@facility_level[facility]=level

    # Create debug level if it's not already created
    @@debug_level=0 if !defined?(@@debug_level)
  end

  def debug_level
    @@debug_level
  end

  # level - level to show message (Integer)
  # :var - variable to show (Object)
  # :msg - message to be prepended before variable  (String)
  # :truncate - truncate var if it is over N characters
  # :overload - do not show or error if debug_level is not set
  # :facility - Which debug facility level should also be used
  # :stack_pos - Stack position to use for calling function information (0==last function)
  def debug(level,args={})
    variable=args[:var] || :zzempty
    message=args[:msg] || nil
    facility=args[:facility] || nil
    raise "Facility must be a symbol" if facility && facility.class!=Symbol
    truncate=args[:truncate] || 0
    raise "Truncate must be an Integer" if truncate.class!=Fixnum
    overload=(!args[:overload].nil? && args[:overload]==true) || false
    stack_pos=args[:stack_pos] || 0
    raise ":stack_pos must be an Integer" if stack_pos.class!=Fixnum

    return if overload
    raise "Call set_debug before using debug" if !defined?(@@debug_level)

    if facility
      facility_level=@@facility_level[facility]
      raise("Unknown facility type: #{facility.to_s}") if facility_level.nil?
      show_debug=level<=facility_level
    else
      show_debug=level<=@@debug_level
    end

    if show_debug

      if facility
        header="D#{level}(#{facility.to_s})"
      else
        header="D#{level}"
      end

      #Example:  "./libs/lexer.rb:650:in `item'"
      #parse the caller array to determine who called us, what line, and what file
      caller[stack_pos]=~/(.*):(\d+):.*`(.*?)'/

      if $1
        #sometimes the debug function gets called from within an exception block, in which cases the backtrace is not
        #available.
        path=$1
        debug_line=$2
        debug_func=$3
        path=path.split("/")

        if (len=path.length)>2
          debug_file=".../#{path[len-2]}/#{path[len-1]}"
        else
          debug_file=path
        end

        header+=" #{debug_file}:#{debug_func}:#{debug_line}"
      else
        header+=" --from exception--"
      end

      if variable.nil?
        strval="nil"
      elsif variable==:zzempty || variable==""
        strval=""
      elsif variable.class==String
        strval=variable
      else
        strval=variable.inspect
      end

      if truncate>0 && truncate<strval.length
        o_strval=strval
        strval=o_strval[0..(truncate/2)]
        strval+= "  .....  "
        strval+=o_strval[(o_strval.length-(truncate/2))..o_strval.length]
      end

      if message
        strval = variable==:zzempty ?
            message :
            message + ": " + strval
      end
      puts "#{header} #{strval}"
    end
  end

  def debug_facility(facility,level,variable="",message=nil,truncate=nil)
    debug(level, :var=>variable, :msg=>message, :truncate=>truncate, :stack_pos=>1)
  end

end  # end Debug module
