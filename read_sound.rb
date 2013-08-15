##
## http://stackoverflow.com/questions/15031544/extract-fast-fourier-transform-data-from-file
##

require 'rubygems'
require "ruby-audio"
require "fftw3"
require 'gruff'

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
      fft_slice = (FFTW3.fft(na)/na.length).to_a[0, window_size/2]
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
puts fft[0][0].inspect

puts "************ WAVE ***********"
puts wave[0..9].inspect

g = Gruff::Line.new
g.title = "Wave output"

g.data("Wave", wave)

g.labels = {0 => 'Wave'}

g.write('my_wave.png')

g = Gruff::Line.new
g.title = "FFT output"

puts "fft.size = #{fft.size}"
puts "fft[0].size = #{fft[0].size}"
g.data("FFT0 Real", fft[0].map(&:real))
# g.data("FFT100 Real", fft[100].map(&:real))
g.data("FFT2000 Real", fft[2000].map(&:real))
#g.data("FFT0 Imag", fft[0].map(&:imag))

g.labels = {0 => 'FFT0 Real', 1 => 'FFT2000 Real'}

g.write('my_fft0.png')
