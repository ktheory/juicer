require 'fileutils'
require 'test/unit'
require 'redgreen'
require 'shoulda'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib juicer])) unless defined?(Juicer)

$data_dir = File.join(File.expand_path(File.dirname(__FILE__)), "data")
Juicer::LOGGER = Logger.new StringIO.new

# Prefixes paths with the data dir
def path(path)
  File.join($data_dir, path)
end

# Allow for testing of private methods inside a block:
#
#  MyClass.publicize_methods do
#    assert MyClass.some_private_method
#  end
class Class
  def publicize_methods
    saved_private_instance_methods = self.private_instance_methods
    self.class_eval { public(*saved_private_instance_methods) }
    yield
    self.class_eval { private(*saved_private_instance_methods) }
  end
end

#
# Intercept calls to open, and return local files
#
module Kernel
 private
  alias juicer_original_open open # :nodoc:

  def open(name, *rest, &block)
    if name =~ /http.+yuicompressor-(\d\.\d\.\d)\.zip$/
      name = File.join($data_dir, "..", "bin", "yuicompressor-#{$1}.zip")
    elsif name =~ /http.+yuilibrary/
      name = File.join($data_dir, "..", "bin", "yuicompressor")
    elsif name =~ /http.+jslint/
      name = File.join($data_dir, "..", "bin", "jslint.js")
    elsif name =~ /ftp.+rhino(.+)\.zip/
      name = File.join($data_dir, "..", "bin", "rhino#{$1}.zip")
    end

    juicer_original_open(File.expand_path(name), *rest, &block)
  end

  module_function :open
end

module Juicer
  module Test

    # Alot of Juicer functionality are filesystem operations. This class sets up files
    # to work on
    class FileSetup
      attr_reader :file_count

      def initialize(dir = $data_dir)
        @dir = dir
        @file_count = 0
      end

      # Recursively deletes the data directory
      def delete
        res = FileUtils.rm_rf(@dir) if File.exist?(@dir)
      end

      # Set up files for unit tests
      def create(force = false)
        return if File.exist?(@dir) && !force

        delete if File.exist?(@dir)
        mkdir @dir
        mkfile(@dir, 'a.css', "@import 'b.css';\n\n/* Dette er a.css */")
        mkfile(@dir, 'a.js', "/**\n * @depend b.js\n */\n\n/* Dette er a.js */")
        mkfile(@dir, 'b.css', "/* Dette er b.css */")
        mkfile(@dir, 'b.js', "/**\n * @depends a.js\n */\n\n/* Dette er b.css */")
        mkfile(@dir, 'a1.css', "@import 'b1.css';\n@import 'c1.css';\nbody {\n    width: 800px;\n}\n")
        mkfile(@dir, 'b1.css', "@import 'd1.css';\n\nhtml {\n    background: red;\n}\n")
        mkfile(@dir, 'c1.css', "h1 {\n    font-size: 12px;\n}\n")
        mkfile(@dir, 'd1.css', "h2 {\n    font-size: 10px;\n}\n")
        mkfile(@dir, 'ok.js', "function hey() {\n    alert(\"Hey\");\n}\n")
        mkfile(@dir, 'not-ok.js', "var a = 34\nb = 78;\n")

        images = mkdir File.join(@dir, "images")
        mkfile(images, '1.png', "")

        css_dir = mkdir File.join(@dir, "css")
        mkfile(css_dir, '2.gif', "")

        css = <<-CSS
body {
    background: url(../images/1.png);
}

h1 {
    background: url(../a1.css) 0 0 no-repeat;
}

h2 {
   background: url(2.gif) no-repeat;
}
        CSS

        mkfile(css_dir, 'test.css', css)
        mkfile(css_dir, 'test2.css', "body { background: url(/images/1.png); }")
        mkfile(@dir, 'path_test.css', "@import 'css/test.css';\n\nbody {\n    background: url(css/2.gif) no-repeat;\n}\n")

        css = <<-CSS
body {
    background: url(/images/1.png);
}

h1 {
    background: url(/css/2.gif);
    background: url(/a1.css) 0 0 no-repeat;
}

h2 {
   background: url(/css/2.gif) no-repeat;
}

p { background: url(/a2.css); }
        CSS

        mkfile(@dir, 'path_test2.css', css)

        mkfile(@dir, 'Changelog.txt', "2008.02.09 | stb-base 1.29\n\nFEATURE: Core  | Bla bla bla bla bla\nFEATURE: UI: | Bla bla bla bla bla\n\n\n2008.02.09 | stb-base 1.29\n\nFEATURE: Core  | Bla bla bla bla bla\nFEATURE: UI: | Bla bla bla bla bla\n")
      end

     private
      # Create a file
      def mkfile(parent, name, content)
        file = File.open(File.join(parent, name), 'w+') { |f| f.puts content }
        @file_count += 1
      end

      def mkdir(dir)
        FileUtils.mkdir(dir)
        @file_count += 1
        dir
      end
    end
  end
end
