require 'test_helper'

class SpriteMapTest < Test::Unit::TestCase
  include SpriteHelper
  
  def setup
    Hash.send(:include, Compass::Sprites::SassExtensions::Functions::VariableReader)
    create_sprite_temp
    file = StringIO.new(<<-CONFIG)
      project_path = "#{@images_proj_path}"
      images_dir = "#{@images_tmp_dir}"
    CONFIG
    Compass.add_configuration(file, "sprite_config")
    Compass.configure_sass_plugin!
    @options = {'cleanup' => Sass::Script::Bool.new(true), 'layout' => Sass::Script::String.new('vertical')}
    @base = sprite_map_test(@options)
  end

  def teardown
    clean_up_sprites
    @base = nil
  end
  
  def test_should_have_the_correct_size
    assert_equal [10,40], @base.size
  end
  
  def test_should_have_the_sprite_names
    assert_equal Compass::Sprites::Importer.sprite_names(URI), @base.sprite_names
  end
  
  def test_should_have_image_filenames
    assert_equal Dir["#{@images_tmp_path}/selectors/*.png"].sort, @base.image_filenames
  end
  
  def test_should_need_generation
    assert @base.generation_required?
  end
  
   def test_uniqueness_hash
    assert_equal '4c703bbc05', @base.uniqueness_hash
  end
  
  def test_should_be_outdated
    assert @base.outdated?
  end

  def test_should_have_correct_filename
    assert_equal File.join(@images_tmp_path, "#{@base.path}-s#{@base.uniqueness_hash}.png"), @base.filename
  end
  
 def test_should_return_the_ten_by_ten_image
    assert_equal 'ten-by-ten', @base.image_for('ten-by-ten').name
    assert @base.image_for('ten-by-ten').is_a?(Compass::Sprites::SassExtensions::Image)
  end
  
 def test_should_have_selectors
   %w(target hover active).each do |selector|
     assert @base.send(:"has_#{selector}?", 'ten-by-ten')
     assert_equal "ten-by-ten_#{selector}", @base.image_for('ten-by-ten').send(:"#{selector}").name

     map = sprite_map_test(:seperator => '-')
     map.images.each_index do |i|
       if map.images[i].name != 'ten-by-ten'
         name = map.images[i].name.gsub(/_/, '-')
         map.images[i].stubs(:name).returns(name)
       end
     end
     assert_equal "ten-by-ten-#{selector}", map.image_for('ten-by-ten').send(:"#{selector}").name
   end
 end

  def test_should_generate_sprite
    @base.generate
    assert File.exists?(@base.filename)
    assert !@base.generation_required?
    assert !@base.outdated?
  end
  
  def test_should_remove_old_sprite_when_generating_new
    @base.generate
    file = @base.filename
    assert File.exists?(file), "Original file does not exist"
    file_to_remove = File.join(@images_tmp_path, 'selectors', 'ten-by-ten.png')
    FileUtils.rm file_to_remove
    assert !File.exists?(file_to_remove), "Failed to remove sprite file"
    @base = sprite_map_test(@options)
    @base.generate
    assert !File.exists?(file), "Sprite file did not get removed"
  end
  
  def test_should_get_correct_relative_name
    Compass.reset_configuration!
    uri = 'foo/*.png'
    other_folder = File.join(@images_tmp_path, '../other-temp')
    FileUtils.mkdir_p other_folder
    FileUtils.mkdir_p File.join(other_folder, 'foo')
    %w(my bar).each do |file|
      FileUtils.touch(File.join(other_folder, "foo/#{file}.png"))
    end
    config = Compass::Configuration::Data.new('config')
    config.images_path = @images_tmp_path
    config.sprite_load_path = [@images_tmp_path, other_folder]
    Compass.add_configuration(config, "sprite_config")
    assert_equal 'foo/my.png', Compass::Sprites::SassExtensions::SpriteMap.relative_name(File.join(other_folder, 'foo/my.png'))
    FileUtils.rm_rf other_folder
  end
  
  def test_should_get_correct_relative_name_for_directories_with_similar_names
    Compass.reset_configuration!
    uri = 'foo/*.png'
    other_folder = File.join(@images_tmp_path, '../other-temp')
    other_folder2 = File.join(@images_tmp_path, '../other-temp2')

    FileUtils.mkdir_p other_folder
    FileUtils.mkdir_p other_folder2
    
    FileUtils.mkdir_p File.join(other_folder2, 'foo')
    %w(my bar).each do |file|
      FileUtils.touch(File.join(other_folder2, "foo/#{file}.png"))
    end
    
    config = Compass::Configuration::Data.new('config')
    config.images_path = @images_tmp_path
    config.sprite_load_path = [@images_tmp_path, other_folder, other_folder2]
    Compass.add_configuration(config, "sprite_config")

    assert_equal 'foo/my.png', Compass::Sprites::SassExtensions::SpriteMap.relative_name(File.join(other_folder2, 'foo/my.png'))
  ensure
    FileUtils.rm_rf other_folder
    FileUtils.rm_rf other_folder2
  end
  
  test "should create map for nested" do
    base = Compass::Sprites::SassExtensions::SpriteMap.from_uri OpenStruct.new(:value => 'nested/squares/*.png'), @base.instance_variable_get(:@evaluation_context), @options
    assert_equal 'squares', base.name
    assert_equal 'nested/squares', base.path
  end
  
  test "should have correct position on ten-by-ten" do
    percent = Sass::Script::Number.new(50, ['%'])
    base = sprite_map_test(@options.merge('selectors_ten_by_ten_position' => percent))
    assert_equal percent, base.image_for('ten-by-ten').position
  end

  test 'gets name for sprite in search path' do
    Compass.reset_configuration!
    uri = 'foo/*.png'
    other_folder = File.join(@images_tmp_path, '../other-temp')
    FileUtils.mkdir_p other_folder
    FileUtils.mkdir_p File.join(other_folder, 'foo')
    %w(my bar).each do |file|
      FileUtils.touch(File.join(other_folder, "foo/#{file}.png"))
    end
    config = Compass::Configuration::Data.new('config')
    config.images_path = @images_tmp_path
    config.sprite_load_path = [@images_tmp_path, other_folder]
    Compass.add_configuration(config, "sprite_config")
    image = Compass::SassExtensions::Sprites::Image.new(@base, "foo/my.png", {})
    assert_equal File.expand_path(File.join(other_folder, 'foo/my.png')), image.file
    assert_equal 0, image.size
  end
  
end
