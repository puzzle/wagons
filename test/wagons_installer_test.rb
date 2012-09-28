require 'test_helper'

class Wagons::InstallerTest < ActiveSupport::TestCase
  
  WAGONFILE = 'Wagonfile.test'
  
  attr_reader :installer
  
  setup :setup_gems, :stub_installer, :stub_wagons, :create_wagonfile
  teardown :remove_wagonfile
  
  test "available only returns latest versions" do
    assert_equal [@master2, @slave1, @superliner2], installer.available
  end
  
  test "not_installed does not return updates" do
    assert_equal [@superliner2], installer.not_installed
  end
  
  test "updates returns higher versions" do
    assert_equal [@master2], installer.updates
  end
  
  test "find installed" do
    assert_equal @master1, installer.installed_spec("#{app_name}_master")
    assert_nil installer.installed_spec("#{app_name}_superliner")
  end
  
  test "find available" do
    assert_equal @master2, installer.available_spec("#{app_name}_master")
    assert_equal @superliner2, installer.available_spec("#{app_name}_superliner")
    assert_nil installer.available_spec("#{app_name}_fantasy")
  end
  
  test "check app dependency is fine if app is sufficient" do
    installer.stubs(:wagon_class).with(@slave1).returns(stub(:app_requirement => Gem::Requirement.new('1.0')))
    assert_equal [], installer.check_app_requirement([@master2, @slave1])
  end
  
  test "check app dependency fails if app is too old" do
    installer.stubs(:wagon_class).with(@superliner2).returns(stub(:app_requirement => Gem::Requirement.new('>= 2.0')))
    msg = installer.check_app_requirement([@master2, @superliner2])
    assert_equal 1, msg.size
    assert_match /requires/, msg.first 
  end
  
  test "check dependencies is fine if all depts are installed at the same time" do
    installer.stubs(:installed).returns([])
    assert_nil installer.check_dependencies([@master2, @superliner1])
    assert_nil installer.check_dependencies([@slave1, @master2])
  end
  
  test "check dependencies fails if dependency is missing" do
    installer.stubs(:installed).returns([])
    assert_match /requires/, installer.check_dependencies([@slave1])
  end
  
  test "check uninstalled dependencies is fine if all depts are uninstalled at the same time" do
    assert_nil installer.check_uninstalled_dependencies([@slave1, @master1])
  end
  
  test "check uninstalled dependencies fails if dependency remains" do
    assert_match /requires/, installer.check_uninstalled_dependencies([@master1])
  end
  
  test "exclude specs does not modify original collection" do
    original = [@master2, @slave1, @superliner1]
    assert_equal [@master2], installer.exclude_specs(original, [@slave1, @superliner2])
    assert_equal [@master2, @slave1, @superliner1], original
  end
  
  test "specs from name" do
    assert_equal [@master2, @slave1], installer.specs_from_names(["#{app_name}_master", "#{app_name}_slave"])
  end
  
  test "specs_from_names raises exception if spec is not found" do
    assert_raise(RuntimeError) do
      installer.specs_from_names(["#{app_name}_master", "#{app_name}_fantasy", "#{app_name}_superliner"])
    end
  end
  
  test "wagonfile update updates version and add new entries" do
    installer.wagonfile_update([@master2, @slave1, @superliner2])
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master', '2.0.0'$/, content
    assert_match /^gem '#{app_name}_slave', '1.0.0'$/, content
    assert_match /^gem '#{app_name}_superliner', '2.0.0'$/, content
    assert_equal 3, content.each_line.count, content
  end
  
  test "wagonfile update keeps existing and add new entries if version should not be included in wagonfile" do
    installer.include_version_in_wagonfile = false
    installer.wagonfile_update([@master2, @slave1, @superliner2])
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master'$/, content
    assert_match /^gem '#{app_name}_slave'$/, content
    assert_match /^gem '#{app_name}_superliner'$/, content
    assert_equal 3, content.each_line.count, content
  end
  
  test "wagonfile update updates commented gems" do
    File.open(WAGONFILE, 'w') do |f|
      f.puts "gem '#{app_name}_master', '1.0.0'"
      f.puts "# gem '#{app_name}_slave', '1.0.0'"
    end
    installer.wagonfile_update([@master2, @slave1])
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master', '2.0.0'$/, content
    assert_match /^gem '#{app_name}_slave', '1.0.0'$/, content
    assert_equal 2, content.each_line.count, content
  end
  
  test "wagonfile remove" do
    installer.wagonfile_remove([@slave1])
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master', '1.0.0'$/, content
    assert_equal 1, content.each_line.count
  end
  
  test "install runs when checks are fine" do
    installer.stubs(:setup_command).returns("echo $RAILS_ENV > env.tmp")
    assert_nil installer.install(["#{app_name}_master"])
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master', '2.0.0'$/, content
    assert_equal 'test', File.read('env.tmp').strip
    File.delete('env.tmp')
  end
  
  test "install fails when setup command fails" do
    installer.stubs(:setup_command).returns("echo $RAILS_ENV; echo 'its a bug' >&2; exit 1")
    assert_equal 'its a bug', installer.install(["#{app_name}_master"]).strip
    content = File.read(WAGONFILE)
    assert_match /^gem '#{app_name}_master', '1.0.0'$/, content
  end
  
  test "install fails when checks go wrong" do
    installer.stubs(:wagon_class).with(@superliner2).returns(stub(:app_requirement => Gem::Requirement.new('>= 2.0')))
    installer.expects(:wagonfile_edit).never
    assert_match /requires/, installer.install(["#{app_name}_superliner"])
  end
  
  test "install fails when name is invalid" do
    installer.expects(:wagonfile_edit).never
    assert_match /not found/, installer.install(["#{app_name}_fantasy"])
  end
  
  test "uninstall runs when checks are fine" do
    installer.expects(:remove_wagons).once
    assert_nil installer.uninstall(["#{app_name}_master", "#{app_name}_slave"])
    content = File.read(WAGONFILE)
    assert_blank content
  end
  
  test "uninstall fails when checks go wrong" do
    installer.expects(:wagonfile_edit).never
    assert_match /requires/, installer.uninstall(["#{app_name}_master"])
  end
  
  test "uninstall fails when name is invalid" do
    installer.expects(:wagonfile_edit).never
    assert_match /not found/, installer.uninstall(["#{app_name}_fantasy"])
  end
  
  test "wagon class can load class from anywhere" do
    installer.unstub(:wagon_class)
    dir = File.expand_path('../dummy/vendor/wagons/superliner', __FILE__)
    spec = Gem::Specification.load(File.join(dir, 'dummy_superliner.gemspec'))
    spec.stubs(:gem_dir).returns(dir)
    assert_equal 'DummySuperliner::Wagon', installer.wagon_class(spec).name
    assert installer.wagon_class(spec).app_requirement.satisfied_by?(Gem::Version.new('1.0'))
  end
  
  private
  
  def setup_gems
    @master1 = gemspec('master', '1.0.0')
    @master2 = gemspec('master', '2.0.0')
    @slave1 = gemspec('slave', '1.0.0', 'master')
    @superliner1 = gemspec('superliner', '1.0.0')
    @superliner2 = gemspec('superliner', '2.0.0')
    
    Wagons.app_version = '1.0.0'
  end
  
  def stub_installer
    @installer = Wagons::Installer.new
    @installer.stubs(:load_available_specs).returns([@master1, @master2, @slave1, @superliner1, @superliner2])
    @installer.stubs(:installed).returns([@master1, @slave1])
    @installer.stubs(:wagonfile).returns(WAGONFILE)
    @installer.stubs(:remove_wagons).returns(nil)
    @installer.stubs(:wagon_class).returns(stub(:app_requirement => Gem::Requirement.new))
  end
  
  def stub_wagons
    Wagons.stubs(:find).returns(stub(:protect? => false))
  end
  
  def create_wagonfile
    File.open(WAGONFILE, 'w') do |f|
      installer.installed.each do |spec|
        f.puts "gem '#{spec.name}', '#{spec.version}'"
      end
    end
  end
  
  def remove_wagonfile
    File.delete(WAGONFILE) if File.exists?(WAGONFILE)
  end
  
  def app_name
    @app_name ||= Wagons.app_name
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