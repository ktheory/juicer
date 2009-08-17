#
# Defines the <tt>Juicer::CSS</tt> API for interacting with CSS resources
#
module Juicer
  #
  # Interface with new and existing CSS files. The API can be
  # used to import all dependencies and export the resulting CSS to a new file
  # or IO stream. This result can then be fed to a compressor for compact results.
  #
  # <tt>Juicer::CSS</tt> supports several custom observation points too, where
  # you can insert custom modules to process CSS as it's being moved between
  # files, merged and compressed.
  #
  # A few examples
  #
  #   # Create a new CSS object (ie, not referring to an existing file on disk)
  #   css = Juicer::CSS.new
  #
  #   # Same as @import url(myfile.css); from a CSS file: depend on another CSS
  #   # resource.
  #   css.depend Juicer::CSS.new("myfile.css")
  #
  #   # You can depend on the file directly, Juicer will wrap it in a Juicer::CSS
  #   # object for you
  #   css.depend "myfile.css"
  #
  #   # import is an alias for depend
  #   css.import "myfile.css"
  #
  #   # ...as is <<
  #   css << "myfile.css"
  #
  #   # List all dependencies
  #   css.dependencies #=> [#<Juicer::CSS:"myfile.css">]
  #
  #   # List all resources. This includes self in the list:
  #   css.resources    #=> [#<Juicer::CSS:[unsaved]>, #<Juicer::CSS:"myfile.css">]
  #
  #   # Export the CSS resource to a file. Will include @import statements for any
  #   # dependencies
  #   file = File.open("myfile.css", "w")
  #   css.export(file)
  #   file.close
  #
  #   # If you'd rather include the contents of the dependencies inline you can
  #   # specify the :inline_dependencies option:
  #   css.export(file, :inline_dependencies => true)
  #
  #   # There are a few alternative ways to export contents:
  #
  #   # Write to open file handler
  #   File.open("myfile.css", "w")
  #   css.export(file)
  #   file.close
  #
  #   # Export to filename, analogous to above example
  #   css.export("myfile.css")
  #
  #   # Export in File.open block
  #   File.open("myfile.css", "w") { |f| css.export(f) }
  #
  #   # Read contents from CSS
  #   File.open("myfile.css", "w") { |f| f.write(css.read) }
  #
  #   # concat is an alias to read(:inline_dependencies => true)
  #   File.open("myfile.css", "w") { |f| f.write(css.concat) }
  #
  #   # Of course, any IO stream is acceptable
  #   css.export(StringIO.new)
  #
  #   # Wrap an existing CSS resource in a Juicer::CSS instance
  #   css = Juicer::CSS.new("myfile.css")
  #   css.dependencies # Lists all @import'ed files (recursively) as Juicer::CSS objects
  #
  #   # Add an observer to the concat operation. Adds cache busters to all URLS,
  #   # one CSS resource at a time
  #   css.observe :before_concat, Juicer::CSSCacheBuster.new
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  class CSS
    attr_reader :file

    def initialize(file, options = {})
      @file = file
    end

    def dependencies
    end

    def resources
      [file] + dependencies
    end

    def read(options = {})
    end

    def export(ios)
    end

    def concat(options = {})
      read(options.merge(:inline_dependencies => true))
    end

    def depend(resource)
    end

    alias << depend
    alias import depend

    def inspect
      filename = file.nil? ? "[unsaved]" : "\"#{file}\""
      "#<#{self.class}:#{filename}>"
    end
  end
end