require 'uri'
require 'fileutils'
require 'open-uri'

require 'starruby'

module StarRuby

  class RemoteFile
    @@base = nil
    def self.get(path, exts = [ '', '.TTF', '.png' ])
      a = URI.parse(path)
      if a.scheme && !@@base
        @@base = a
        to_local a, File.basename(path), exts
        return File.basename(path)
      else
        unless File.exist?(a.path)
          if @@base
            to_local URI.join(@@base.to_s, path), path, exts
          end
        end
      end
      path
    end
    
    def self.to_local(uri, path, exts)
      exts.each do |ext|
        begin
          src = open(uri.to_s + ext, 'rb')
          FileUtils.mkdir_p File.dirname(path)
          File.open(path + ext, 'wb') do |f|
            f.write src.read
          end
          src.close
          return
        rescue OpenURI::HTTPError
        end
      end
    end
  end
  
  class <<Font
    alias _new new
    def new(path, opt)
      _new RemoteFile.get(path), opt
    end
  end
  
  class <<Texture
    alias _load load
    def load(path)
      _load RemoteFile.get(path)
    end
  end
  
end  

alias _require require

def require(path)
  begin
    _require path
  rescue LoadError
    StarRuby::RemoteFile.get(path, ['.rb'])
    _require path    
  end
end
  

include StarRuby

load RemoteFile.get(ARGV[0])

