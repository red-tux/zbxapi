#!/usr/bin/ruby

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


#setup our search path or libraries
path=File.expand_path(File.dirname(__FILE__) + "/./")+"/"

begin
  require 'rubygems'
rescue LoadError
  puts
  puts "Ruby Gems failed to load.  Please install Ruby Gems using your systems"
  puts "package management program or downlaod it from http://rubygems.org."
  puts
  exit 1
end

require 'optparse'
require 'ostruct'
require path+'libs/zdebug'
require path+'libs/defines'
require path+"libs/check_dependencies"
require path+'libs/zabcon_globals'

if RUBY_VERSION=="1.8.6"  #Ruby 1.8.6 lacks the each_char function in the string object, so we add it here
  String.class_eval do
    def each_char
      if block_given?
        scan(/./m) do |x|
          yield x
        end
      else
        scan(/./m)
      end
    end
  end
end


class ZabconApp

  def initialize
    setup_opt_parser
  end

  def setup_opt_parser
    @options=OpenStruct.new
#    @options.debug=0


    @opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options] [command file]"
      opts.separator "------------------------------------"
      opts.separator ""
      opts.separator "If command file is specified Zabcon will read from the file"
      opts.separator "line by line and execute the commands in order.  If '-' is "
      opts.separator "used, Zabcon will read from stdin as though it were a file."
      opts.separator ""
      opts.separator "Options"
      opts.on("-h", "-?", "--help", "Display this help message") do
        EnvVars.instance["echo"]=false
        @options.help           =true
        puts opts
      end
      opts.on("-l", "--load [file]", "load configuration file supplied or ","default if none") do |file|
        if file.nil?
          @options.configfile="zabcon.conf"
        else
          @options.configfile=file
        end
      end
      opts.on("-d", "--debug LEVEL", Integer, "Specify debug level (Overrides config","file)") do |level|
        @options.debug=level
      end
      opts.on("-e", "--[no-]echo", "Enable startup echo.  Default is on ","for interactive") do |echo|
        EnvVars.instance["echo"]=echo
      end
      opts.on("-s", "--separator CHAR", "Seperator character for csv styple output.",
              "Use \\t for tab separated output.") do |sep|
        EnvVars.instance["table_separator"]=sep
      end
      opts.on("--no-header", "Do not show headers on output.") do
        EnvVars.instance["table_header"]=false
      end
    end
  end

  def setup_globals
    env=EnvVars.instance  # we must instantiate a singleton before using it
    vars=GlobalVars.instance

    env["debug"]=( @options.debug.nil? ? 0 : @options.debug )
    env["show_help"]=false
    env["server"]=''
    env["username"]=''
    env["password"]=''
    env["lines"]=24
    env["language"]="english"
    env["logged_in"]=false
    env["have_tty"]=STDIN.tty?
    EnvVars.instance["echo"]=STDIN.tty? ? true: false

    #output related environment variables
    env["table_output"]=STDIN.tty?   # Is the output a well formatted table, or csv like?
    env["table_header"]=true
    env["table_separator"]=","
   end

  def run
#    p ARGV
    setup_globals
    begin
      @opts.parse!(ARGV)
    rescue OptionParser::InvalidOption  => e
      puts e
      puts
      puts @opts
      exit(1)
    rescue OptionParser::InvalidArgument => e
      puts e
      puts
      puts @opts
      exit(1)
    end

    puts RUBY_PLATFORM if EnvVars.instance["echo"]

    check_dependencies("1.8.6","parseconfig", "json", "highline")
    #check_dependencies("0.0.0","parseconfig", "json", "highline")

    begin
      require 'readline'
    rescue LoadError
      puts "Readline support was not compiled into Ruby.  Readline support is required."
      exit
    end

    #If we don't have the each_char method for the string class include the module that has it.
    if !String.method_defined?("each_char")
      begin
        require 'jcode'
      rescue LoadError
        puts "Module jcode is required for your version of Ruby"
      end
    end

    path=File.expand_path(File.dirname(__FILE__) + "/./")+"/"  #TODO: make this less clugey
    require path+'libs/zabcon_core'   #Require placed after deps check

#    p @options
    if @options.help.nil?
      zabcon=ZabconCore.new(@options)
      zabcon.start()
    end
  end
end

if __FILE__ == $0

zabconapp=ZabconApp.new()
zabconapp.run()

end
