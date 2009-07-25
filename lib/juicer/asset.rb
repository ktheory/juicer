#
# Assets are files used by CSS and JavaScript files. The Asset class provides
# tools for manipulating asset paths, such as rebasing, adding cache busters,
# and cycling asset hosts.
#
# Asset objects are most commonly created by <tt>Juicer::Asset::PathResolver#resolve</tt>
# which resolves include paths to file names. It is possible, however, to use
# the asset class directly:
#
#   Dir.pwd                                                       #=> "/home/christian/projects/mysite/design/css"
#   asset = Juicer::Asset.new "../images/logo.png"
#   asset.path                                                    #=> "../images/logo.png"
#   asset.path(:context => "~/projects/mysite/design")            #=> "images/logo.png"
#   asset.filename                                                #=> "/home/christian/projects/mysite/design/images/logo.png"
#   asset.path(:cache_buster_type => :soft)                       #=> "../images/logo.png?jcb=1234567890"
#   asset.path(:cache_buster_type => :soft, :cache_buster => nil) #=> "../images/logo.png?1234567890"
#   asset.path(:cache_buster => "bustIT")                         #=> "../images/logo.png?bustIT=1234567890"
#
#   asset = Juicer::Asset.new "../images/logo.png", :document_root => "/home/christian/projects/mysite"
#   asset.absolute_path(:cache_buster_type => :hard)              #=> "/images/logo-jcb1234567890.png"
#
# @author Christian Johansen (christian@cjohansen.no)
#
class Juicer::Asset
  attr_reader :options

  #
  # Initialize asset at <tt>path</tt>. Accepts an optional hash of options:
  #
  # * <tt>:context</tt> Context from which asset is required. Given a <tt>path</tt> of
  #   <tt>../images/logo.png</tt> and a <tt>:context</tt> of <tt>/project/design/css</tt>,
  #   the asset file will be assumed to live in <tt>/project/design/images/logo.png</tt>
  #   Defaults to the current directory.
  # * <tt>:host</tt> Include hostname when asking for absolute path. Default is empty.
  # * <tt>:protocol</tt> Supports host, default is http://
  # * <tt>:document_root</tt> The root directory for absolute URLs (ie, the server's document
  #   root). This option is needed when resolving absolute URLs, and when generating absolute URLs.
  #
  def initialize(path, options = {})
    @path = path
    @filename = nil
    @absolute_path = nil
    @relative_path = nil

    @options = {
      :context => Dir.pwd,
      :host => "",
      :protocol => "http",
      :document_root => nil
    }.merge(options)
  end

  #
  # Returned path will include host if option was set when object was created
  # (requires the <tt>:protocol</tt> option).
  #
  # Juicer::Asset#filename is required to return a valid filename. In addition,
  # the <tt>:document_root</tt> option is required.
  #
  def absolute_path
    return @absolute_path if @absolute_path

    host = self.options[:host] || ""
    require :document_root
    require :protocol if host != ""

    @absolute_path = filename.sub(%r{^#{self.options[:document_root]}}, '').sub(/^\/?/, '/')
    @absolute_path = "#{self.options[:protocol]}://#{host}#@absolute_path" if host != ""
    @absolute_path
  end

  #
  # Return relative path.
  #
  def relative_path
    return @relative_path if @relative_path

    require :context

    context = Pathname.new(self.options[:context])
    @relative_path = Pathname.new(filename).relative_path_from(context).to_s
  end

  alias path relative_path

  #
  # Return filename on disk. Requires the <tt>:context</tt> option to be set for
  # relative URLs, and <tt>:document_root</tt> for absolute ones.
  #
  # If asset path includes protocol and host, it needs to match the matching options.
  # A mismatched host and/or protocol will raise an exception.
  #
  def filename
    return @filename if @filename

    # Verfiy pre conditions
    protocol_pattern = %r{^[a-zA-Z]{3,5}://}
    is_absolute = @path =~ %r{^([a-zA-Z]{3,5}:/)?/}
    has_host = @path =~ protocol_pattern
    require :context unless is_absolute || has_host
    require :document_root if is_absolute
    require [:host, :protocol] if has_host

    # Remove hostname
    path = @path.sub(%r{^#{options[:protocol]}://#{options[:host]}}, '')

    # Fail if host is still set
    if path =~ protocol_pattern
      msg = "Unable to resolve filename for #{path} using #{options[:protocol]}://#{options[:host]}"
      raise ArgumentError.new(msg)
    end

    # Figure out filename
    base = is_absolute ? options[:document_root] : options[:context]
    @filename = File.expand_path(File.join(base, path))
  end

  #
  # Returns basename of filename on disk
  #
  def basename
    File.basename(filename)
  end

  #
  # Returns basename of filename on disk
  #
  def dirname
    File.dirname(filename)
  end

  #
  # Returns <tt>true</tt> if file exists on disk
  #
  def exists?
    File.exists?(filename)
  end

 private
  #
  # Require an option. Raise <tt>ArgumentError</tt> if option is nil
  #
  def require(type, msg = nil)
    [type].flatten.each do |type|
      msg ||= "No #{type.to_s.gsub(/_/, ' ')} set"
      raise ArgumentError.new(msg) unless self.options[type]
    end
  end
end
