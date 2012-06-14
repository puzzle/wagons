require 'test_helper'

class Wagons::InstallerTest < ActiveSupport::TestCase
  
  WAGONFILE = 'Wagonfile.test'
  
  setup :setup_gems, :stub_installer, :stub_wagons, :create_wagonfile
  teardown :remove_wagonfile
  
  test "available only returns latest versions" do
    assert_equal [@master2, @slave1, @superliner2], Wagons::Installer.available
  end
  
  test "not_installed does not return updates" do
    assert_equal [@superliner2], Wagons::Installer.not_installed
  end
  
  test "updates returns higher versions" do
    assert_equal [@master2], Wagons::Installer.updates
  end
  
  test "find installed" do
    assert_equal @master1, Wagons::Installer.installed_spec("#{app_name}_master")
    assert_nil Wagons::Installer.installed_spec("#{app_name}_superliner")
  end
  
  test "find available" do
    assert_equal @master2, Wagons::Installer.available_spec("#{app_name}_master")
    assert_equal @superliner2, Wagons::Installer.available_spec("#{app_name}_superliner")
    assert_nil Wagons::Installer.available_spec("#{app_name}_fantasy")
  end
  
  test "check app dependency is fine if app is sufficient" do
    Wagons::Installer.stubs(:wagon_class).with(@slave1).returns(stub(:app_requirement => Gem::Requirement.new('1.0')))
    assert_equal [], Wagons::Installer.check_app_requirement([@master2, @slave1])
  end
  
  test "check app dependency fails if app is too old" do
    Wagons::Installer.stubs(:wagon_class).with(@superliner2).returns(stub(:app_requirement => Gem::Requirement.new('>= 2.0')))
    msg = Wagons::Installer.check_app_requirement([@master2, @superliner2])
    assert_equal 1, msg.size
    assert_match /requires/, msg.first 
  end
  
  test "check dependencies is fine if all depts are installed at the same time" do
    Wagons::Installer.stubs(:installed).returns([])
    assert_nil Wagons::Installer.check_dependencies([@master2, @superliner1])
    assert_nil Wagons::Installer.check_dependencies([@slave1, @master2])
  end
  
  test "check dependencies fails if dependency is missing" do
    Wagons::Installer.stubs(:installed).returns([])
    assert_match /requires/, Wagons::Installer.check_dependencies([@slave1])
  end
  
  test "check uninstalled dependencies is fine if all depts are uninstalled at the same time" do
    assert_nil Wagons::Installer.check_uninstalled_dependencies([@slave1, @master1])
  end
  
  test "check uninstalled dependencies fails if dependency remains" do
    assert_match /requires/, Wagons::Installer.check_uninstalled_dependencies([@master1])
  end
  
  test "exclude specs does not modify original collection" do
    original = [@master2, @slave1, @superliner1]
    assert_equal [@master2], Wagons::Installer.exclude_specs(original, [@slave1, @superliner2])
    assert_equal [@master2, @slave1, @superliner1], original
  end
  
  test "specs from name" do
    assert_equal [@master2, @slave1], Wagons::Installer.specs_from_names(["#{app_name}_master", "#{app_name}_slave"])
  end
  
  test "specs_from_names raises exception if spec is not found" do
    assert_raise(RuntimeError) do
      Wagons::Installer.specs_from_names(["#{app_name}_master", "#{app_name}_fantasy", "#{app_name}_superliner"])
    end
  end
  
  test "wagonfile update updates version and add new entries" do
    Wagons::Installer.wagonfile_update([@master2, @slave1, @superliner2])
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master', '2.0.0'$/, content
    assert_match /^gem '#{app_name}_slave', '1.0.0'$/, content
    assert_match /^gem '#{app_name}_superliner', '2.0.0'$/, content
    assert_equal 3, content.each_line.count, content
  end
  
  test "wagonfile update updates commented gems" do
    File.open(WAGONFILE, 'w') do |f|
      f.puts "gem '#{app_name}_master', '1.0.0'"
      f.puts "# gem '#{app_name}_slave', '1.0.0'"
    end
    Wagons::Installer.wagonfile_update([@master2, @slave1])
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master', '2.0.0'$/, content
    assert_match /^gem '#{app_name}_slave', '1.0.0'$/, content
    assert_equal 2, content.each_line.count, content
  end
  
  test "wagonfile remove" do
    Wagons::Installer.wagonfile_remove([@slave1])
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master', '1.0.0'$/, content
    assert_equal 1, content.each_line.count
  end
  
  test "install runs when checks are fine" do
    assert_nil Wagons::Installer.install(["#{app_name}_master"])
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master', '2.0.0'$/, content
  end
  
  test "install fails when checks go wrong" do
    Wagons::Installer.stubs(:wagon_class).with(@superliner2).returns(stub(:app_requirement => Gem::Requirement.new('>= 2.0')))
    Wagons::Installer.expects(:wagonfile_edit).never
    assert_match /requires/, Wagons::Installer.install(["#{app_name}_superliner"])
  end
  
  test "install fails when name is invalid" do
    Wagons::Installer.expects(:wagonfile_edit).never
    assert_match /not found/, Wagons::Installer.install(["#{app_name}_fantasy"])
  end
  
  test "uninstall runs when checks are fine" do
    Wagons::Installer.expects(:remove_wagons).once
    assert_nil Wagons::Installer.uninstall(["#{app_name}_master", "#{app_name}_slave"])
    content = File.read(WAGONFILE)
    assert_blank content
  end
  
  test "uninstall fails when checks go wrong" do
    Wagons::Installer.expects(:wagonfile_edit).never
    assert_match /requires/, Wagons::Installer.uninstall(["#{app_name}_master"])
  end
  
  test "uninstall fails when name is invalid" do
    Wagons::Installer.expects(:wagonfile_edit).never
    assert_match /not found/, Wagons::Installer.uninstall(["#{app_name}_fantasy"])
  end
  
  private
  
  def setup_gems
    @master1 = gemspec('master', '1.0.0')
    @master2 = gemspec('master', '2.0.0')
    @slave1 = gemspec('slave', '1.0.0', 'master')
    @superliner1 = gemspec('superliner', '1.0.0')
    @superliner2 = gemspec('superliner', '2.0.0')
    
    Wagon.app_version = '1.0.0'
  end
  
  def stub_installer
    Wagons::Installer.stubs(:load_available_specs).returns([@master1, @master2, @slave1, @superliner1, @superliner2])
    Wagons::Installer.stubs(:installed).returns([@master1, @slave1])
    Wagons::Installer.stubs(:wagonfile).returns(WAGONFILE)
    Wagons::Installer.stubs(:remove_wagons).returns(nil)
    Wagons::Installer.stubs(:wagon_class).returns(stub(:app_requirement => Gem::Requirement.new))
  end
  
  def stub_wagons
    Wagon.stubs(:find).returns(stub(:protect? => false))
  end
  
  def create_wagonfile
    File.open(WAGONFILE, 'w') do |f|
      Wagons::Installer.installed.each do |spec|
        f.puts "gem '#{spec.name}', '#{spec.version}'"
      end
    end
  end
  
  def remove_wagonfile
    File.delete(WAGONFILE) if File.exists?(WAGONFILE)
  end
  
  def app_name
    @app_name ||= Wagon.app_name
  end
  
  def gemspec(name, version, dependency = nil)
    Gem::Specification.new do |s|
      s.name = "#{app_name}_#{name}"
      s.version = version
      s.summary = 'blabla'
      
      s.add_dependency "#{app_name}_#{dependency}" if dependency
    end
  end
      
  
end