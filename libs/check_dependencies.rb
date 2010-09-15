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

def check_dependencies(*dependencies)
  puts "Checking dependencies" if EnvVars.instance["echo"]
  depsok=true  #assume we will not fail dependencies

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

