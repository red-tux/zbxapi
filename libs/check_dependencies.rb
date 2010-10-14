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
# $Id: $
# $Revision$
##########################################

#setup our search path or libraries
path=File.expand_path(File.dirname(__FILE__) + "/../libs")+"/"

require "rubygems"

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

