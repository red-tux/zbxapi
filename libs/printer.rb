#GPL 2.0  http://www.gnu.org/licenses/gpl-2.0.html
#Zabbix CLI Tool and associated files
#Copyright (C) 2009,2010 Andrew Nelson nelsonab(at)red-tux(dot)net
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
# $Id$
# $Revision$
##########################################

require 'libs/zdebug'
require 'libs/zabcon_globals'

if RUBY_PLATFORM =~ /.*?mswin.*?/
  require 'Win32API'

  Kbhit = Win32API.new("crtdll", "_kbhit", 'V', 'L')
  Getch = Win32API.new("crtdll", "_getch", 'V', 'L')

  def getch
    Getch.call
  end

  def kbhit
    Kbhit.call
  end
end

require 'highline/system_extensions'

class OutputPrinter

  include ZDebug
  include HighLine::SystemExtensions

  NILCHAR="--"

#  attr_accessor :sheight

  # Class initializer
  # Interactive mode will not be implemented for a while so the variable
  # is more of a place holder for now.  Interactive
  def initialize(interactive=true)
    @swidth=80                  # screen width
    @interactive=interactive    # mode for output
    @lines=0                    # how many lines have been displayed thus far?

    # Check the environment variables to see if screen height has been set
    EnvVars.instance["sheight"]=25 if EnvVars.instance["sheight"].nil?
  end

  def hash_width(item)
    w=0
    item.each do |value, index|
      w+= value.length + index.length + 6   # 6 is for " => " and ", "
    end
    w-=2  # subtract out last comma and space
    return w
  end

  def array_width(item)
    w=0
    item.each do |value|
      w+=value.length + 2  # 2 is for ", "
    end
    w-=2  # remove last comma and space
    return w
  end

  def getitemwidth(item)
    retval=0
    return NILCHAR.length if item.nil?
    case item.class.to_s
      when "String"
        retval=item.length
      when "Fixnum"
        retval=item.to_s.length
      when "Float"
        retval=item.to_s.length
      when "Hash"
        retval=hash_width(item)
      when "Array"
        retval=array_width(item)
      else
        p item
        raise "getitemwidth - item.class: #{item.class} not supported"
    end
    retval
  end

  # determines the max col width for each colum
  # may need to be optimized in the future
  # possible optimization may include randomly iterating through list for large lists
  # if dataset is an array headers is ignored, also an integer is returned not an array
  # of widths
  def getcolwidth(dataset,headers=nil)
    if dataset.class==Array then
      widths=headers.collect {|x| 0}  # setup our resultant array of widths

      # check the widths for the headers
      headers.each_with_index { |value, index| widths[index] = value.length }

      if (dataset.length>0) and (dataset[0].class!=Hash) then
        width=0
        dataset.each do |item|
          w=getitemwidth(item)
          widths[0] = widths[0]<w ? w : widths[0]    # 0 because there's one column
        end
        return widths
      elsif dataset[0].class==Hash then
        raise "getcolwidth headers are nil" if headers.nil?
        dataset.each do |row|
          headers.each_with_index do |value, index|
            width=getitemwidth(row[value])
            val= widths[index]  # storing value for efficiency, next statement might have two of this call
            widths[index]= val < width ? width : val
          end
        end

        return widths
      else
        raise "getcolwidth Unknown internal data type"
      end
    else
      raise "getcolwidth - dataset type not supported: #{dataset.class}"  # need to raise an error
    end
  end

  def format_hash_for_print(item)
    s = ""
    item.each do |value, index|
      s << ", " if !s.empty?
      s << index << " => " << value
    end
    return s
  end

  def format_for_print(item)
    if item.nil? || item==[]
      return NILCHAR
    else
      case item.class.to_s
        when "Hash"
          return format_hash_for_print(item)
        else
          return item
      end
    end
  end

  # Pause output function
  # This function will pause output after n lines have been printed
  # n is defined by the lines parameter
  # If interactive output has been disabled pause will not stop
  # after n lines have been printed
  # If @lines is set to -1 a side effect is created where pause is disabled.
  def pause? (lines=1)
    if @interactive and EnvVars.instance["sheight"]>0 and (@lines>-1) then
      @lines += lines
      if @lines>=(EnvVars.instance["sheight"]-1) then
        pause_msg = "Pause, q to quit, a to stop pausing output"
        Kernel.print pause_msg
        if RUBY_PLATFORM =~ /.*?mswin.*?/
          while kbhit==0
            sleep 0.3
#            putc('.')
          end
          chr=getch
          puts chr
        else
          begin
            chr=get_character
          rescue Interrupt  # trap ctrl-c and create side effect to behave like "q" was pressed
            chr=113
          end

          # erase characters on the current line, and move the cursor left the size of pause_msg
          Kernel.print "\033[2K\033[#{pause_msg.length}D"

          if (chr==113) or (chr==81) then  # 113="q"  81="Q"
            raise "quit"
          end
          if (chr==65) or (chr==97) then # 65="A"  97="a
            @lines=-1
          end
        end
        @lines= (@lines==-1) ? -1:0  # if we set @lines to -1 make sure the side effect propagates
      end
    end
  end

  def printline(widths)
    output="+"
    widths.each { |width| output+="-"+("-"*width)+"-+" }
    pause? 1
    puts output
  end

  #Prints the table header
  #header: Array of strings in the print order for the table header
  #order: Array of strings denoting output order
  #widths: (optional) Array of numbers denoting the width of each field
  #separator: (optional) Separator character
  def printheader(header, widths=nil, separator=",")
    if widths.nil?
      output=""
      header.each do |value|
        output+="#{value}#{separator}"
      end
      separator.length.times {output.chop!}
    else
      output="|"
      header.each_with_index do |value, index|
        output+=" %-#{widths[index]}s |" % value
      end
    end
    puts output
    pause? 1
  end

  #Requires 2 arguments and 2 optional arguments
  #row: The Row of data
  #order: An array of field names with the order in which they are to be printed
  #Optional arguments
  #widths: An array denoting the width of each field, if nul a table separated by separator will be printed
  #separator: the separator character to be used
  def printrow(row, order, widths=nil, separator=',')
    if widths.nil?
      output=""
      order.each_with_index do |value, index|
        output+="#{row[value]}#{separator}"
      end
      separator.length.times { output.chop! }  #remove the last separator
      puts output
    else
      output="|"
      order.each_with_index do |value, index|
        output+=" %-#{widths[index]}s |" % format_for_print(row[value])
      end
      puts output
    end
    pause? 1
  end

  def print_array(dataset,cols)
    debug(6,dataset,"dataset",150)
    debug(6,cols,"cols",50)
    count=0
    type=dataset[:class]
    results=dataset[:result]

    debug(6,type,"Array type")

    puts "#{dataset[:class].to_s.capitalize} result set"  if EnvVars.instance["echo"]

    if results.length==0
      puts "Result set empty"
    elsif results[0].class==Hash then
      debug(7,"Results type is Hash")
      header=[]
      if cols.nil? then
        case type
          when :user
            header=["userid","alias"]
          when :host
            header=["hostid","host"]
          when :item
            header=["itemid","description","key_"]
          when :hostgroup
            header=["groupid","name"]
          when :hostgroupid
            header=["name", "groupid", "internal"]
          when :raw
            header=results[0].keys
          when nil
            header=results[0].keys
        end
      elsif cols.class==Array
        header=cols
      elsif cols=="all" then
        puts "all cols"
        results[0].each_key { |key| header<<key }
      else
        header=cols.split(',')
      end

      debug(6,header,"header")

      widths=getcolwidth(results,header)

      if EnvVars.instance["table_output"]
        if EnvVars.instance["table_header"]
          printline(widths)
          printheader(header,widths)
        end
        printline(widths)
        results.each { |row| printrow(row,header,widths) }
        printline(widths)
        puts "#{results.length} rows total"
      else
        printheader(header,nil,EnvVars.instance["table_separator"]) if EnvVars.instance["table_header"]
        results.each { | row| printrow(row,header,nil,EnvVars.instance["table_separator"]) }
      end


    else
      debug(7,"Results type is not Hash, assuming array")
      widths = getcolwidth(results,["id"])   # always returns an array of widths

      printline(widths)            # hacking parameters to overload functions
      printheader(["id"],widths)
      printline(widths)

      results.each { |item| printrow({"id"=>item},["id"],widths) }
      printline(widths)
      puts "#{results.length} rows total"
    end
  end

  def print_hash(dataset,cols)
    puts "Hash object printing not implemented, here is the raw result"
    p dataset
  end


  def print(dataset,cols)
    begin
      debug(6,dataset,"Dataset",200)
      debug(6,cols,"Cols",40)
      @lines=0
      if !cols   #cols==nil
        cols_to_show=nil
      else
        cols_to_show=cols.empty? ? nil : cols[:show]
      end
    
      puts dataset[:message] if dataset[:message]

#    p dataset[:result].class
      if dataset[:result].class==Array then
        print_array(dataset,cols_to_show)
      elsif dataset[:result].class==Hash then
        print_hash(dataset,cols_to_show)
      elsif dataset[:result].class!=NilClass then
        puts "Unknown object received by the print routint"
        puts "Class type: #{dataset[:result].class}"
        puts "Data:"
        p dataset[:result]
      end
    rescue TypeError
      puts "***********************************************************"
      puts "Whoops!"
      puts "Looks like we got some data we didn't know how to print."
      puts "This may be worth submitting as a bug.  If you submit a bug"
      puts "report be sure to include this output and the command you"
      puts "executed to get this message.  http://trac.red-tux.net"
      puts "data received:"
      p dataset
    rescue RuntimeError => e
      if e.message=="quit" then
        puts "Output stopped"
      else
        raise e
      end
    end
  end

end
