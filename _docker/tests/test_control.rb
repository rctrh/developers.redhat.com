require 'fileutils'
require 'json'

require_relative 'test_helper'
require_relative 'my_fake_network'
require_relative 'system_call_wrapper'
require_relative '../control'

class TestControl < Minitest::Test

  def test_get_docker_container

    container_name = 'searchisko_1'
    environment = mock()
    environment.expects(:get_compose_project_name).returns('foo')

    container_json = '{"NetworkSettings": {"Ports": [8080]}}'

    container = mock()
    container.expects(:json).returns(JSON.parse(container_json))
    Docker::Container.expects(:get).with('foo_searchisko_1').returns(container)

    assert_equal(container, get_docker_container(environment, container_name))

  end

  def test_determine_docker_host_for_container_ports_with_docker_host_alias

      host_ip = '10.20.30.40'
      Socket.expects(:gethostname).returns('localhost')
      Resolv.expects(:getaddress).with('localhost').returns(host_ip)

      docker_machine_ip = '192.168.0.1'
      Resolv.expects(:getaddress).with('docker').returns(docker_machine_ip)

      assert_equal(docker_machine_ip, determine_docker_host_for_container_ports)
  end

  def test_determine_docker_host_for_container_ports_with_no_docker_host_alias

    host_ip = '10.20.30.40'

    Socket.expects(:gethostname).returns('localhost')
    Resolv.expects(:getaddress).with('localhost').returns(host_ip)
    Resolv.expects(:getaddress).with('docker').raises(StandardError.new('No docker alias here!'))

    assert_equal(host_ip, determine_docker_host_for_container_ports)
  end


  def test_start_and_wait_for_supporting_services

    environment = mock()
    environment.expects(:create_template_resources)
    environment.expects(:template_resources)
    supporting_services = %w(drupal)

    system_exec = mock()
    system_exec.expects(:execute_docker_compose).with(environment, :up, %w(-d --no-recreate).concat(supporting_services))
    expects(:block_wait_searchisko_started)
    expects(:block_wait_drupal_started)

    start_and_wait_for_supporting_services(environment, supporting_services, system_exec)

  end

  def test_start_and_wait_for_supporting_services_nil_service_list

    environment = mock()
    system_exec = mock()
    start_and_wait_for_supporting_services(environment, nil, system_exec)

  end

  def test_start_and_wait_for_supporting_services_empty_service_list
    environment = mock()
    system_exec = mock()
    start_and_wait_for_supporting_services(environment, [], system_exec)
  end


  def test_build_environment_resources

    environment = mock()
    system_exec = mock()

    environment.expects(:is_drupal_environment?).returns(false)
    environment.expects(:environment_name).returns('foo')

    expects(:copy_project_dependencies_for_awestruct_image)
    expects(:build_css_and_js_for_drupal).never
    expects(:build_base_docker_images).with(system_exec)
    expects(:build_environment_docker_images).with(environment, system_exec)

    build_environment_resources(environment, system_exec)

  end

  def test_build_environment_resources_for_drupal_environment

    environment = mock()
    system_exec = mock()

    environment.expects(:is_drupal_environment?).returns(true)
    environment.expects(:environment_name).returns('foo')

    expects(:build_css_and_js_for_drupal)
    expects(:copy_project_dependencies_for_awestruct_image)
    expects(:build_base_docker_images).with(system_exec)
    expects(:build_environment_docker_images).with(environment, system_exec)

    build_environment_resources(environment, system_exec)

  end

  def test_build_base_docker_images
    system_exec = mock();

    system_exec.expects(:execute_docker).with(:build,'--tag=developer.redhat.com/base','./base')
    system_exec.expects(:execute_docker).with(:build,'--tag=developer.redhat.com/java','./java')
    system_exec.expects(:execute_docker).with(:build,'--tag=developer.redhat.com/ruby','./ruby')

    build_base_docker_images(system_exec)

  end

  def test_build_environment_docker_images

    environment = mock()
    system_exec = mock()

    system_exec.expects(:execute_docker_compose).with(environment, :build)

    build_environment_docker_images(environment, system_exec)
  end


  def test_copy_project_dependencies_for_awestruct_image

    gemfile = mock();
    gemfile_lock = mock();
    target_gemfile = mock();
    target_gemfile_lock = mock();

    File.expects(:open).with('../Gemfile').returns(gemfile)
    File.expects(:open).with('../Gemfile.lock').returns(gemfile_lock)

    FileHelpers.expects(:open_or_new).with('awestruct/Gemfile').returns(target_gemfile)
    FileHelpers.expects(:open_or_new).with('awestruct/Gemfile.lock').returns(target_gemfile_lock)

    FileHelpers.expects(:copy_if_changed).with(gemfile, target_gemfile)
    FileHelpers.expects(:copy_if_changed).with(gemfile_lock, target_gemfile_lock)

    copy_project_dependencies_for_awestruct_image

  end

  def test_build_css_and_js_for_drupal
    status = mock()

    status.expects(:success?).returns(true).twice
    Open3.expects(:capture2e).with('npm install').returns(['out',status])
    Open3.expects(:capture2e).with('$(npm bin)/gulp').returns(['out',status])

    build_css_and_js_for_drupal

  end

  def test_should_abort_if_cannot_build_css_and_js_running_npm_install

    status = mock()

    status.expects(:success?).returns(false)
    Open3.expects(:capture2e).with('npm install').returns(['out',status])

    assert_raises(SystemExit){
      build_css_and_js_for_drupal
    }
  end

  def test_should_abort_if_cannot_build_css_and_js_for_drupal_running_gulp
    status = mock()

    status.expects(:success?).twice.returns(true).then.returns(false)
    Open3.expects(:capture2e).with('npm install').returns(['out',status])
    Open3.expects(:capture2e).with('$(npm bin)/gulp').returns(['Oh dear!',status])

    assert_raises(SystemExit){
      build_css_and_js_for_drupal
    }

  end

  def test_load_environment_aborts_execution_if_environment_does_not_exist
    assert_raises(SystemExit){
      load_environment(:environment => nil)
    }
  end

  def test_load_environment_continues_if_environment_exists
      load_environment(:environment => mock())
  end

  def test_returns_true_when_supporting_service_in_list
    supporting_services = %w"drupal mysql searchisko drupalmysql"
    assert_equal(true, check_supported_service_requested(supporting_services, 'drupal'))
  end

  def test_returns_false_when_supporting_service_not_in_list
    supporting_services = %w"mysql searchisko"
    assert_equal(false, check_supported_service_requested(supporting_services, 'drupal'))
  end

  def test_returns_false_when_supporting_service_list_is_empty
    assert_equal(false, check_supported_service_requested([], 'drupal'))
  end

  def test_returns_false_when_supporting_service_list_is_nil
    assert_equal(false, check_supported_service_requested(nil, 'drupal'))
  end

  def test_kill_current_environment_with_network

    network = MyFakeNetwork.new(1)
    wrapper = SystemCallWrapper.new(network)
    environment = mock()
    environment.expects(:environment_name).returns('foo').at_least_once
    environment.expects(:get_compose_project_name).returns('rhdpr1')

    Docker::Network.stubs(:get).with('rhdpr1_default').returns network

    wrapper.kill_current_environment(environment)
    assert network.deleted?, 'Network was not deleted'
  end


  def test_kill_current_environment_without_network

    network = MyFakeNetwork.new(1)
    wrapper = SystemCallWrapper.new(network)
    environment = mock()
    environment.expects(:environment_name).returns('foo').at_least_once
    environment.expects(:get_compose_project_name).returns('rhdpr1')

    Docker::Network.stubs(:get).with('rhdpr1_default').raises Docker::Error::NotFoundError
    wrapper.kill_current_environment(environment)

    refute network.deleted?, 'Network was deleted when it should not have been'
  end

end