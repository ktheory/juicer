require File.expand_path(File.join(File.dirname(__FILE__), "chainable"))
require File.expand_path(File.join(File.dirname(__FILE__), "cache_buster"))

module Juicer
  #
  # The CssCacheBuster is a tool that can parse a CSS file and substitute all
  # referenced URLs by a URL appended with a timestamp denoting it's last change.
  # This causes the URLs to be unique every time they've been modified, thus
  # facilitating using a far future expires header on your web server.
  #
  # See Juicer::CacheBuster for more information on how the cache buster URLs
  # work.
  #
  # When dealing with CSS files that reference absolute URLs like /images/1.png
  # you must specify the :web_root option that these URLs should be resolved
  # against.
  #
  # When dealing with full URLs (ie including hosts) you can optionally specify
  # an array of hosts to recognize as "local", meaning they serve assets from
  # the :web_root directory. This way even asset host cycling can benefit from
  # cache busters.
  #
  class CssCacheBuster
    include Juicer::Chainable

    def initialize(options = {})
      options[:document_root] ||= options[:web_root]
      @type = options[:type] || :soft
      @path_resolver = Juicer::Asset::PathResolver.new options
      @contents = nil
    end

    #
    # Update file. If no +output+ is provided, the input file is overwritten
    #
    def save(file, output = nil)
      raise FileNotFoundError.new unless File.exists?(file)
      @contents = File.read(file)
      @path_resolver.base = File.dirname(file)
      target = !output.nil? ? File.dirname(output) : nil
      used = []

      urls(file).each do |url|
        asset = @path_resolver.resolve(url)
        asset = asset.rebase(target) unless target.nil?

        begin
          path = asset.path(:cache_buster_type => @type)
          @contents.gsub!(url, path)
        rescue ArgumentError
          puts "Unable to locate file #{url}, skipping cache buster"
        end
      end

      File.open(output || file, "w") { |f| f.puts @contents }
      @contents = nil
    end

    chain_method :save

    #
    # Returns all referenced URLs in +file+. Returned paths are absolute (ie,
    # they're resolved relative to the +file+ path.
    #
    def urls(file)
      @contents = File.read(file) unless @contents

      (@contents.scan(/url\([\s"']*([^\)"'\s]*)[\s"']*\)/m).collect do |match|
        match.first
      end).uniq
    end
  end
end
