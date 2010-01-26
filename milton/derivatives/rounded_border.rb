require 'milton/derivatives/rounded'

module Milton
  class RoundedBorder < Rounded
    def process
      raise "rounding radius must be specified (i.e. :rounded_border => { :radius => '5px' })" unless options.has_key?(:radius)
      
      radius = options[:radius].gsub(/\D/, '')
      color  = "'#{options[:border_color] || '#000000'}'"
      width  = (options[:border_width] || '1').gsub(/\D/, '')
      
      temp_src   = File.join(settings[:tempfile_path], Milton::Tempfile.from(@source.filename))
      temp_dst   = self.class.pngify(File.join(settings[:tempfile_path], Milton::Tempfile.from(@source.filename)))
      temp_matte = File.join(settings[:tempfile_path], Time.now.to_f.to_s + '.mvg')
      
      @source.copy(temp_src)
      
      # Recipe from: http://www.imagemagick.org/Usage/thumbnails/#rounded_border
      # Note that it generates a third tempfile
      cmd = "convert #{temp_src}
        -format 'roundrectangle 0,0 %[fx:w+#{width}],%[fx:h+#{width}] #{radius},#{radius}'
        -write info:#{temp_matte} -matte -bordercolor none -border #{width}
        \\(
          +clone -alpha transparent -background none 
          -fill white -stroke none -strokewidth 0 -draw @#{temp_matte}
        \\)
        -compose DstIn -composite
        \\(
          +clone -alpha transparent -background none
          -fill none -stroke #{color} -strokewidth #{width} -draw @#{temp_matte} 
        \\)
        -compose Over -composite
        #{temp_dst}".gsub(/\n/, '')
      Milton.syscall!(cmd)
    
      raise "failed to generate rounded-corner image: #{temp_dst} from #{@source.filename} using #{cmd}" unless File.exist?(temp_dst)
      file.store(temp_dst)
    end
  end
end
