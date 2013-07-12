##
## http://stackoverflow.com/questions/15031544/extract-fast-fourier-transform-data-from-file
##

require "ruby-audio"
require "fftw3"

fname = ARGV[0]
window_size = 1024
wave = Array.new
fft = Array.new(window_size/2,[])

begin
  buf = RubyAudio::Buffer.float(window_size)
  RubyAudio::Sound.open(fname) do |snd|
    while snd.read(buf) != 0
      wave.concat(buf.to_a)
      na = NArray.to_na(buf.to_a)
      fft_slice = FFTW3.fft(na).to_a[0, window_size/2]
      j=0
      fft_slice.each { |x| fft[j] << x; j+=1 }
    end
  end

rescue => err
  puts "error reading audio file: #{err}"
  exit
end

# now I can work on analyzing the "fft" and "wave" arrays...
puts "************ FFT ***********"
puts fft.inspect

# puts "************ WAVE ***********"
# puts wave.inspect
