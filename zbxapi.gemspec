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

#Zabbix API Ruby Interface GemSpec file

spec = Gem::Specification.new do |s|
  s.name = %q{zbxapi}
  s.rubyforge_project = "zbxapi"
  s.version = "0.1"
  s.authors = ["A. Nelson"]
  s.email = %q{nelsonab@red-tux.net}
  s.summary = %q{Ruby wrapper to the Zabbix API}
  s.homepage = %q{http://trac.red-tux.net/}
  s.description = %q{Provides a straight forward interface to manipulate Zabbix servers using the Zabbix API.}
  s.licenses = "LGPL 2.1"
  s.requirements = "Requires json"
  s.add_dependency('json')
  s.require_paths =["."]
  s.files =
    ["zbxapi.rb", "libs/zdebug.rb", "libs/api_exceptions.rb",
     "libs/exceptions.rb"]
end
