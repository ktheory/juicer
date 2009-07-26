require "test_helper"

class AssetTest < Test::Unit::TestCase
  context "initializing asset" do
    should "use default options" do
      asset = Juicer::Asset.new "../images/logo.png"

      assert_equal Dir.pwd, asset.base
      assert_equal [], asset.hosts
      assert_nil asset.document_root
    end

    should "override options" do
      base = "/home/me/project/awesome-site/public/stylesheets"
      asset = Juicer::Asset.new "../images/logo.png", :base => base

      assert_equal base, asset.base
    end

    should "not nil base option" do
      asset = Juicer::Asset.new "../images/logo.png", :base => nil

      assert_equal Dir.pwd, asset.base
    end

    should "accept a single host" do
      asset = Juicer::Asset.new "../images/logo.png", :hosts => "http://localhost"

      assert_equal ["http://localhost"], asset.hosts
    end

    should "accept array of hosts" do
      asset = Juicer::Asset.new "../images/logo.png", :hosts => ["http://localhost", "http://dev.server"]

      assert_equal ["http://localhost", "http://dev.server"], asset.hosts
    end

    should "strip trailing slash in hosts" do
      asset = Juicer::Asset.new "../images/logo.png", :hosts => ["http://localhost/", "http://dev.server"]

      assert_equal ["http://localhost", "http://dev.server"], asset.hosts
    end

    should "strip add scheme for hosts if missing" do
      asset = Juicer::Asset.new "../images/logo.png", :hosts => ["localhost", "http://dev.server"]

      assert_equal ["http://localhost", "http://dev.server"], asset.hosts
    end

    should "strip trailing slash and add scheme in hosts" do
      asset = Juicer::Asset.new "../images/logo.png", :hosts => ["localhost/", "http://dev.server", "some.server/"]

      assert_equal ["http://localhost", "http://dev.server", "http://some.server"], asset.hosts
    end
  end

  context "asset absolute path" do
    should "raise exception without document root" do
      asset = Juicer::Asset.new "../images/logo.png"

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

    should "return absolute path from absolute path" do
      base = "/var/www/public/stylesheets"
      document_root = "/var/www/public"
      path = "/images/logo.png"
      asset = Juicer::Asset.new path, { :base => base, :document_root => document_root }

      assert_equal path, asset.absolute_path
    end

    context "with host" do
      setup do
        base = "/var/www/public/stylesheets"
        document_root = "/var/www/public"
        options = { :base => base, :document_root => document_root }
        @asset = Juicer::Asset.new "../images/logo.png", options
      end

      should "return absolute path with host" do
        assert_equal "http://localhost/images/logo.png", @asset.absolute_path(:host => "http://localhost")
      end

      should "strip trailing slash from absolute path host" do
        assert_equal "http://localhost/images/logo.png", @asset.absolute_path(:host => "http://localhost/")
      end

      should "ensure scheme in absolute path host" do
        assert_equal "http://localhost/images/logo.png", @asset.absolute_path(:host => "localhost")
      end

      should "strip trailing slash and ensure scheme in absolute path host" do
        assert_equal "http://localhost/images/logo.png", @asset.absolute_path(:host => "localhost/")
      end
    end
  end

  context "relative path" do
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

    should "raise exception with absolute path with host without hosts" do
      options = { :document_root => "/var/project" }
      asset = Juicer::Asset.new "http://localhost/images/logo.png", options

      assert_raise ArgumentError do
        asset.filename
      end
    end

    should "raise exception with mismatching hosts" do
      options = { :document_root => "/var/project", :hosts => %w[example.com site.com] }
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
      asset = Juicer::Asset.new "http://localhost/images/logo.png", :document_root => "/var/www/public", :hosts => "localhost"

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end

    should "raise exception when hosts match but schemes don't" do
      options = { :document_root => "/var/www/public", :hosts => "http://localhost" }
      asset = Juicer::Asset.new "https://localhost/images/logo.png", options

      assert_raise(ArgumentError) { asset.filename }
    end

    should "return filename from absolute path with host and document root" do
      options = { :document_root => "/var/www/public", :hosts => "https://localhost" }
      asset = Juicer::Asset.new "https://localhost/images/logo.png", options

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end

    should "return filename from absolute path with hosts and document root" do
      options = { :document_root => "/var/www/public", :hosts => %w[example.com localhost https://localhost] }
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
