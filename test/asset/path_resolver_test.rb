require "test_helper"

class AssetPathResolverTest < Test::Unit::TestCase
  context "resolving path" do
    should "return asset object with the same options as the resolver" do
      resolver = Juicer::Asset::PathResolver.new :document_root => "/var/www", :hosts => ["localhost", "mysite.com"]
      asset = resolver.resolve("../images/logo.png")

      assert_equal resolver.base, asset.base
      assert_equal resolver.document_root, asset.document_root
      assert_equal resolver.hosts, asset.hosts
    end
  end
end
