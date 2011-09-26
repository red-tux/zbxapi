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

require 'rubygems'
require "test/unit"
require "api_tests/test_utilities"
require 'zbxapi/zdebug'

class TC_Test_00_Debug < Test::Unit::TestCase
  include ZDebug

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    set_debug_level(0)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown

  end

  def test_00_debug_5
    out = capture_stdout do
      set_debug_level(0)
      debug(1,:msg=>"none",:var=>"none")
    end
    assert_equal("",out.string)
  end


  def test_00_debug_10
    out = capture_stdout do
      set_debug_level(1)
      debug(1)
    end
    assert_match(/^D1 \.\.\.\/api_tests\/tc_test_debug\.rb:test_00_debug_10:\d+ $/,out.string)
  end

  def test_00_debug_15
    out = capture_stdout do
      set_debug_level(1)
      debug(1,:msg=>"none",:var=>"none")
    end
    assert_match(/^D1 \.\.\.\/api_tests\/tc_test_debug\.rb:test_00_debug_15:\d+ none: none$/,out.string)
  end

  def test_00_debug_20
    out = capture_stdout do
      set_debug_level(1)
      debug(1,:var=>"Truncation Test",:truncate=>4)
    end
    assert_match(/^D1 \.\.\.\/api_tests\/tc_test_debug\.rb:test_00_debug_20:\d+ Tru  \.\.\.\.\.  st$/,out.string)
  end

  def test_00_debug_25
    out = capture_stdout do
      set_debug_level(1)
      debug(1,:trace_depth=>3)
    end

    assert_match(/^\[.+zdebug\.rb:each:\d+.+zdebug\.rb:debug:\d+.+tc_test_debug\.rb:test_00_debug_25:\d+\]$/,out.string)
  end


end
