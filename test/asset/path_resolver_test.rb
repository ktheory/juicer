require "test_helper"

class AssetPathResolverTest < Test::Unit::TestCase
  context "initializing path resolver" do
    should "use current directory as base" do
      resolver = Juicer::Asset::PathResolver.new

      assert_equal Dir.pwd, resolver.base
    end

    should "ensure all hosts are complete with scheme" do
      resolver = Juicer::Asset::PathResolver.new :hosts => %w[localhost my.project]

      assert_equal %w[http://localhost http://my.project], resolver.hosts
    end

    should "set document root" do
      resolver = Juicer::Asset::PathResolver.new :document_root => Dir.pwd

      assert_equal Dir.pwd, resolver.document_root
    end
  end

  context "resolving path" do
    should "return asset object with the same options as the resolver" do
      resolver = Juicer::Asset::PathResolver.new :document_root => "/var/www", :hosts => ["localhost", "mysite.com"]
      asset = resolver.resolve("../images/logo.png")

      assert_equal resolver.base, asset.base
      assert_equal resolver.document_root, asset.document_root
      assert_equal resolver.hosts, asset.hosts
    end
  end

  context "cycling hosts" do
    should "return one host at a time" do
      resolver = Juicer::Asset::PathResolver.new :hosts => %w[localhost my.project]

      assert_equal "http://localhost", resolver.cycle_hosts
      assert_equal "http://my.project", resolver.cycle_hosts
      assert_equal "http://localhost", resolver.cycle_hosts
    end

    should "be aliased through host" do
      resolver = Juicer::Asset::PathResolver.new :hosts => %w[localhost my.project]

      assert_equal "http://localhost", resolver.host
      assert_equal "http://my.project", resolver.host
      assert_equal "http://localhost", resolver.host
    end
  end
end
