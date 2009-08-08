#!/usr/bin/env ruby
['base', '../dependency_resolver/css_dependency_resolver'].each do |lib|
  require File.expand_path(File.join(File.dirname(__FILE__), lib))
end

require 'pathname'

module Juicer
  module Merger
    # Merge several files into one single output file. Resolves and adds in files
    # from @import statements
    #
    class StylesheetMerger < Base

      # Constructor
      #
      # Options:
      # * <tt>:document_root</tt> - Path to web root if there is any @import statements
      #   using absolute URLs
      #
      def initialize(files = [], options = {})
        @dependency_resolver = CssDependencyResolver.new(options)
        super(files || [], options)
        @path_resolver = Juicer::Asset::PathResolver.new options
        @url_type = options.key?(:absolute_urls) && options[:absolute_urls] ? :absolute_path : nil
        @url_type = options.key?(:relative_urls) && options[:relative_urls] ? :relative_path : @url_type
        @url_type ||= :path
      end

     private
      def root=(path)
        super(path)
        @path_resolver.base = path
      end

      #
      # Takes care of removing any import statements. This avoids importing the
      # file that was just merged into the current file.
      #
      # +merge+ also recalculates any referenced URLs. Relative URLs are adjusted
      # to be relative to the resulting merged file. Absolute URLs are left alone
      # by default. If the :hosts option is set, the absolute URLs will cycle
      # through these. This may help in concurrent downloads.
      #
      # The options hash decides how Juicer recalculates referenced URLs:
      #
      #   options[:absolute_urls] When true, all paths are converted to absolute
      #                           URLs. Requires options[:web_root] to define
      #                           root directory to resolve absolute URLs from.
      #   options[:relative_urls] When true, all paths are converted to relative
      #                           paths. Requires options[:web_root] to define
      #                           root directory to resolve absolute URLs from.
      #
      # If none if these are set then relative URLs are recalculated to match
      # location of merged target while absolute URLs are left absolute.
      #
      # If options[:hosts] is set to an array of hosts, then they will be cycled
      # for all absolute URLs.
      #
      def merge(file)
        content = super.gsub(/^\s*\@import\s("|')(.*)("|')\;?/, '')
        @path_resolver.base = File.expand_path(File.dirname(file))

        content.scan(/url\([\s"']*([^\)"'\s]*)[\s"']*\)/m).uniq.collect do |url|
          url = url.first
          path = @path_resolver.resolve(url).rebase(self.root).send(@url_type, :host => @path_resolver.host)
          content.gsub!(/\(#{url}\)/m, "(#{path})") unless path == url
        end

        content
      end
    end
  end
end

# Run file from command line
#
if $0 == __FILE__
  return puts("Usage: stylesheet_merger.rb file[...] output") if $*.length < 2

  fm = Juicer::Merger::StylesheetMerger.new()
  fm << $*[0..-2]
  fm.save($*[-1])
end
