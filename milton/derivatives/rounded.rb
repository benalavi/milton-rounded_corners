module Milton
  class Rounded < Derivative
    class << self
      # force png extension
      def pngify(filename)
        filename.sub(/#{File.extname(filename)}$/, '.png')
      end
    end
    
    def process
      raise "rounding radius must be specified (i.e. :rounded => { :radius => '5px' })" unless options.has_key?(:radius)
      
      radius   = options[:radius].gsub(/\D/, '')
      temp_src = File.join(settings[:tempfile_path], Milton::Tempfile.from(@source.filename))
      temp_dst = self.class.pngify(File.join(settings[:tempfile_path], Milton::Tempfile.from(@source.filename)))
      
      @source.copy(temp_src)
      
      # Recipe from: http://www.imagemagick.org/Usage/thumbnails/#rounded
      cmd = "convert #{temp_src} \\( +clone -threshold -1 -draw 'fill black polygon 0,0 0,#{radius} #{radius},0 fill white circle #{radius},#{radius} #{radius},0' \\( +clone -flip \\) -compose Multiply -composite \\( +clone -flop \\) -compose Multiply -composite \\) +matte -compose CopyOpacity -composite #{temp_dst}"
      Milton.syscall!(cmd)
    
      raise "failed to generate rounded-corner image: #{temp_dst} from #{@source.filename} using #{cmd}" unless File.exist?(temp_dst)
      file.store(temp_dst)
    end
    
    def filename
      self.class.pngify(super)
    end
  end
end
