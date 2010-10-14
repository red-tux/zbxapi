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

class ZabconApp

  def initialize
    setup_opt_parser
  end

  def setup_opt_parser
    @options=OpenStruct.new
#    @options.debug=0

    @opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.separator "------------------------------------"
      opts.separator ""
      opts.separator "Options"
      opts.on("-h","--help","Display this help message") do
        EnvVars.instance["echo"]=false
        @options.help=true
        puts opts
      end
      opts.on("-l","--load [file]","load configuration file supplied or default if none") do |file|
        if file.nil?
          @options.configfile="zabcon.conf"
        else
          @options.configfile=file
        end
      end
      opts.on("-d","--debug LEVEL",Integer,"Specify debug level (Overrides config file)") do |level|
        @options.debug=level
      end
      opts.on("-e","--echo [on/off]", "Turn startup echo on or off.  Default on") do |echo|
        if echo.nil?
          EnvVars.instance["echo"]=true
        elsif echo.downcase=="on"
          EnvVars.instance["echo"]=true
        elsif echo.downcase=="off"
          EnvVars.instance["echo"]=false
        else
          puts "Invalid value for echo received: #{echo}"
          exit(1)
        end
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
   end

  def run
#    p ARGV
    setup_globals
    @opts.parse!(ARGV)
    puts RUBY_PLATFORM if EnvVars.instance["echo"]

    check_dependencies("1.8.7","parseconfig", "json", "highline")
    #check_dependencies("0.0.0","parseconfig", "json", "highline")

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
