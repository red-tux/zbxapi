#!/usr/bin/ruby

##License:: GPL 2.0  http://www.gnu.org/licenses/gpl-2.0.html
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
# $Id$
# $Revision$
##########################################

$: << File.expand_path(File.join(File.dirname(__FILE__), '..'))

require "test/unit"
require "api_tests/tc_test_user"


class TS_All_Tests
   def self.suite
     suite = Test::Unit::TestSuite.new
     suite << TC_Test_API_User
     return suite
   end
 end
# Test::Unit::UI::Console::TestRunner.run(TS_MyTests)
