#License:: GPL 2.0  http://www.gnu.org/licenses/gpl-2.0.html
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
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.                              d

##########################################
# Subversion information
# $Id: $
# $Revision: $
##########################################

$: << File.expand_path(File.join(File.dirname(__FILE__), '..'))

require "test/unit"
require "zbxapi"

class TC_Test_API_User < Test::Unit::TestCase


  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup

    @server=$server.nil? ? "http://localhost/1.8.4rc3" : $server
    @api_user=$api_user.nil? ? "apitest" : $api_user
    @api_pass=$api_pass.nil? ? "apitest" : $api_pass

    @zbx_api = ZabbixAPI.new(@server)
    @zbx_api.login(@api_user,@api_pass)
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown

  end

  def test_0_bad_logins
    @zbx_api=ZabbixAPI.new("bad")
    assert_raise(ZbxAPI_GeneralError) {@zbx_api.login("bad","pass")}

    @zbx_api=ZabbixAPI.new(@server)
    assert_raise(ZbxAPI_ExceptionBadAuth) {@zbx_api.login("bad",@api_pass)}
  end

  def test_01_create_user
    result=@zbx_api.user.get({"extendoutput"=>true,"limit"=>100})
    result.map! { |item| item["alias"] }
    assert_not_nil(result.grep("apitest")[0])

    assert_nothing_raised(ZbxAPI_GeneralError) {result=@zbx_api.user.create({"name"=>"test", "alias"=>"test", "passwd"=>"test"})}
    @@test_user=result["userids"][0]
  end

  def test_02_addmedia
    #12-24-2010  Bug in the following:
    #https://support.zabbix.com/browse/ZBX-3340
    #Ruby API Library also has a bug which needs to be fixed (parameter checks don't follow API documentation)
    #@zbx_api.debug_level=5
    assert_nothing_raised(ZbxAPI_GeneralError) do
      result=@zbx_api.user.addmedia(
          {"users"=>[{"userid"=>@@test_user}],
           "medias"=>[{"active"=>2,"sendto"=>"me@me.com","severity"=>"123456"}]})
    end
  end

  def test_99_delete_user
    result=nil
    assert_nothing_raised(ZbxAPI_GeneralError) do
      result=@zbx_api.user.delete({"userid"=>@@test_user})
    end
    assert_equal(@@test_user,result["userids"][0])
  end



end