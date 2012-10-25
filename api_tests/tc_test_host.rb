#import variables which describe our local test environment
require "ts_local_vars"


require "test/unit"

class TC_Test_API_Host < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    @server=$server.nil? ? "http://localhost/1.8.4rc3" : $server
    @api_user=$api_user.nil? ? "apitest" : $api_user
    @api_pass=$api_pass.nil? ? "apitest" : $api_pass

    @zbx_api = ZabbixAPI.new(@server,:returnttype=>ApiResult)
    @zbx_api.login(@api_user,@api_pass)

  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  def test_01_create_host
    assert_nothing_raised(ZbxAPI_GeneralError) do
      result =@zbx_api.host.create({"host"=>"test_server", "dns"=>"host.example.com", "proxy_hostid"=>0,
                                   "groups"=>[{"groupid"=>1}], "useip"=>0})
#      @@id=result["hostids"][0].to_i
    end

  end

  def test_02_get_host_with_no_arguments
    assert_nothing_raised(ArgumentError){result=@zbx_api.host.get}
  end

  def test_03_get_host_by_key_of_hash_as_symbol
    assert_nothing_raised(ZbxAPI_ParameterError){result=@zbx_api.host.get({:output=>"extend"})}
  end

  def test_99_delete_host
    id=-1
    assert_nothing_raised(ZbxAPI_GeneralError) do
      result=@zbx_api.host.get("filter"=>{"host"=>["test_server"]})
      id = result[0]["hostid"].to_i
    end

    assert_nothing_raised(ZbxAPI_GeneralError) do
      @zbx_api.host.delete(id)
    end

  end
end
