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
# $Id: zabcon.rb 250 2010-12-24 06:56:38Z nelsonab $
# $Revision: 250 $
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
#require path+"libs/check_dependencies"
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
    @cmd_opts=OpenStruct.new
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
        @cmd_opts.echo=false
        @cmd_opts.help=true
        puts opts
      end
      opts.on("-l", "--load FILE", "load configuration file supplied or ","default if none") do |file|
        @cmd_opts.config_file=file
      end
      opts.on("--no-config", "Do not attempt to automatically load","the configuration file") do
        @cmd_opts.load_config=false
      end
      opts.on("-d", "--debug LEVEL", Integer, "Specify debug level (Overrides config","file)") do |level|
        @cmd_opts.debug=level
      end
      opts.on("-e", "--[no-]echo", "Enable startup echo.  Default is on ","for interactive") do |echo|
        @cmd_opts.echo=echo
      end
      opts.on("-s", "--separator CHAR", "Seperator character for csv styple output.",
              "Use \\t for tab separated output.") do |sep|
        @cmd_opts.table_separator=sep
      end
      opts.on("--no-header", "Do not show headers on output.") do
        @cmd_opts.table_header=false
      end
    end
  end

  def setup_globals
    env=EnvVars.instance  # we must instantiate a singleton before using it
    vars=GlobalVars.instance

    env["debug"]=0
    env["show_help"]=false
    env["server"]=nil
    env["username"]=nil
    env["password"]=nil
    env["lines"]=24
    env["language"]="english"
    env["logged_in"]=false
    env["have_tty"]=STDIN.tty?
    env["echo"]=STDIN.tty? ? true: false
    env["config_file"]="zabcon.conf"
    env["load_config"]=true

    #output related environment variables
    env["table_output"]=STDIN.tty?   # Is the output a well formatted table, or csv like?
    env["table_header"]=true
    env["table_separator"]=","

  end

  #checks to ensure all dependencies are available, forcefully exits with an
  # exit code of 1 if the dependency check fails
  # * ruby_rev is a string denoting the minimum version of ruby suitable
  # * *dependencies is an array of libraries which are required
  def check_dependencies(required_rev,*dependencies)
    puts "Checking dependencies" if EnvVars.instance["echo"]
    depsok=true  #assume we will not fail dependencies

    required_rev=required_rev.split('.')
    ruby_rev=RUBY_VERSION.split('.')
    items=ruby_rev.length < required_rev.length ? ruby_rev.length : required_rev.length

    for i in 0..items-1 do
      if ruby_rev[i]<required_rev[i]
        puts
        puts "Zabcon requires Ruby version #{required_rev.join('.')} or higher."
        puts "you are using Ruby version #{RUBY_VERSION}."
        puts
        exit(1)
      elsif ruby_rev[i]>required_rev[i]
        break
      end
    end

    #Convert the inbound array to a hash
    deps = Hash[*dependencies.collect { |v|
      [v,true]
    }.flatten]

    deps.each_key {|dep|
      val=Gem.source_index.find_name(dep).map {|x| x.name}==[]
      puts " #{dep} : Not Installed" if val
      depsok=false if val
    }
    if !depsok
      puts
      puts "One or more dependencies failed"
      puts "Please see the dependencies file for instructions on installing the"
      puts "required dependencies"
      puts
      exit(1)
    end
  end


  def run
    begin
      setup_globals          # step 1, set up the global environment variables
      @opts.parse!(ARGV)     # step 2, parse the command line and setup the class variable @cmd_opts

      h = @cmd_opts.marshal_dump()  #dump the hash to a temporary variable
      cmd_hash={}
      h.each_pair do |k,v|
        cmd_hash[k.to_s]=v
      end
      EnvVars.instance.load_config(cmd_hash)
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
    rescue OptionParser::MissingArgument => e
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
    if @cmd_opts.help.nil?
      zabcon=ZabconCore.new
      zabcon.start()
    end
  end
end

if __FILE__ == $0

zabconapp=ZabconApp.new()
zabconapp.run()

end
