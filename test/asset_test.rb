require "test_helper"

class AssetTest < Test::Unit::TestCase
  context "initializing asset" do
    should "create asset with default options" do
      asset = Juicer::Asset.new "../images/logo.png"

      assert_equal Dir.pwd, asset.options[:base]
      assert_equal "", asset.options[:host]
      assert_nil asset.options[:document_root]
    end

    should "create asset with overridden options" do
      base = "/home/me/project/awesome-site/public/stylesheets"
      asset = Juicer::Asset.new "../images/logo.png", :base => base

      assert_equal base, asset.options[:base]
    end
  end

  context "asset absolute path" do
    should "raise exception without document root" do
      asset = Juicer::Asset.new "../images/logo.png"

      assert_raise ArgumentError do
        asset.absolute_path
      end
    end

    should "raise exception with host without protocol" do
      options = { :protocol => nil, :host => "localhost", :document_root => "/project" }
      asset = Juicer::Asset.new "../images/logo.png", options

      assert_raise ArgumentError do
        asset.absolute_path
      end
    end

    should "return absolute path from relative path and document root" do
      base = "/var/www/public/stylesheets"
      document_root = "/var/www/public"
      asset = Juicer::Asset.new "../images/logo.png", :base => base, :document_root => document_root

      assert_equal "/images/logo.png", asset.absolute_path
    end

    should "return absolute path with host from relative path and document root" do
      base = "/var/www/public/stylesheets"
      document_root = "/var/www/public"
      options = { :base => base, :document_root => document_root, :host => "localhost" }
      asset = Juicer::Asset.new "../images/logo.png", options

      assert_equal "http://localhost/images/logo.png", asset.absolute_path
    end

    should "return absolute path from absolute path" do
      base = "/var/www/public/stylesheets"
      document_root = "/var/www/public"
      options = { :base => base, :document_root => document_root }
      path = "/images/logo.png"
      asset = Juicer::Asset.new path, options

      assert_equal path, asset.absolute_path
    end
  end

  context "relative path" do
    should "raise exception if base is missing" do
      asset = Juicer::Asset.new "../images/logo.png", :base => nil

      assert_raise ArgumentError do
        asset.relative_path
      end
    end

    should "return relative path from relative path" do
      path = "../images/logo.png"
      asset = Juicer::Asset.new path, :base => "/var/www/public/stylesheets"

      assert_equal path, asset.relative_path
    end

    should "return relative path from absolute path" do
      path = "/images/logo.png"
      asset = Juicer::Asset.new path, :document_root => "/var/www/public", :base => "/var/www/public/stylesheets"

      assert_equal "..#{path}", asset.relative_path
    end

    should "be aliased as path" do
      path = "/images/logo.png"
      asset = Juicer::Asset.new path, :document_root => "/var/www/public", :base => "/var/www/public/stylesheets"

      assert_equal asset.relative_path, asset.path
    end
  end

  context "asset filename" do
    should "raise exception with relative path without base" do
      asset = Juicer::Asset.new "../images/logo.png", :base => nil

      assert_raise ArgumentError do
        asset.filename
      end
    end

    should "raise exception with absolute path without document root" do
      asset = Juicer::Asset.new "/images/logo.png", :document_root => nil

      assert_raise ArgumentError do
        asset.filename
      end
    end

    should "raise exception with absolute path with host without document root" do
      asset = Juicer::Asset.new "http://localhost/images/logo.png", :document_root => nil

      assert_raise ArgumentError do
        asset.filename
      end
    end

    should "raise exception with absolute path with host without host option" do
      options = { :document_root => "/var/project", :host => nil }
      asset = Juicer::Asset.new "http://localhost/images/logo.png", options

      assert_raise ArgumentError do
        asset.filename
      end
    end

    should "raise exception with absolute path with host without protocol option" do
      options = { :document_root => "/var/project", :host => "localhost", :protocol => nil }
      asset = Juicer::Asset.new "http://localhost/images/logo.png", options

      assert_raise ArgumentError do
        asset.filename
      end
    end

    should "raise exception with mismatching hosts" do
      options = { :document_root => "/var/project", :host => "example.com" }
      asset = Juicer::Asset.new "http://localhost/images/logo.png", options

      assert_raise ArgumentError do
        asset.filename
      end
    end

    should "return filename from relative path and base" do
      asset = Juicer::Asset.new "../images/logo.png", :base => "/var/www/public/stylesheets"

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end

    should "return filename from absolute path and document root" do
      asset = Juicer::Asset.new "/images/logo.png", :document_root => "/var/www/public"

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end

    should "return filename from absolute path with host and document root" do
      asset = Juicer::Asset.new "http://localhost/images/logo.png", :document_root => "/var/www/public", :host => "localhost"

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end

    should "return filename from absolute path with host, protocol and document root" do
      options = { :document_root => "/var/www/public", :host => "localhost", :protocol => "https" }
      asset = Juicer::Asset.new "https://localhost/images/logo.png", options

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end
  end

  context "file helpers" do
    should "return file basename" do
      base = "/var/www/public/"
      asset = Juicer::Asset.new "images/logo.png", :base => base

      assert_equal "logo.png", asset.basename
    end

    should "return file dirname" do
      base = "/var/www/public/"
      asset = Juicer::Asset.new "images/logo.png", :base => base

      assert_equal "#{base}images", asset.dirname
    end

    should "verify that file does not exist" do
      base = "/var/www/public/"
      asset = Juicer::Asset.new "images/logo.png", :base => base

      assert !asset.exists?
    end

    context "existing file" do
      setup { File.open("somefile.css", "w") { |f| f.puts "/* Test */" } }
      teardown { File.delete("somefile.css") }

      should "verify that file exists" do
        asset = Juicer::Asset.new "somefile.css"

        assert asset.exists?
      end
    end
  end
end
