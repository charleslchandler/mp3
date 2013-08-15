module Mp3
  module FilterBank
    # P 2.1: Build the input sample vector for subband analysis
    SBLIMIT  = 32
    HAN_SIZE = 512
    SCALE    = 32768

    # x        = ?
    # C        =
    # M        =

    # class SubbandAnalysis
    #   attr_reader :data, :channels
    #
    #   def initialize(data, channels)
    #     @data     = data
    #     @channels = channels
    #   end
    #
    #   def zeros(*dimensions)
    #     NArray.int(*dimensions)
    #   end
    #
    #   def s
    #     # Structure of the output – Subband samples
    #     s = zeros(2, 2, 32, 18)
    #     # initial data offset ...
    #     gr_offset = 0
    #     # SBLIMIT = 32, HAN_SIZE = 512
    #     1..2.each do |gr| # Number of Granules
    #       1..channels.each do |ch| # Number of Channels
    #         0..17.each do |iter| # 18 iterations
    #           # Replace 32 oldest samples with 32 new samples
    #           x(ch, HAN_SIZE..(SBLIMIT+1)) = x(ch, (HAN_SIZE-SBLIMIT)..1);
    #           x(ch, SBLIMIT..1) = data(ch, (gr_offset+iter*SBLIMIT+1)..(gr_offset+(iter+1)*SBLIMIT))/SCALE;
    #         end
    #       end
    #     end
    #   end
    # end

    class SubbandAnalysis

      attr_accessor :off, :x, :filter

      def initialize
        x = [] # was double x[2][HAN_SIZE]
        (1..0).each do |i|
          x[i] = []
          (HAN_SIZE-1..0).each do |j|
            x[i][j] = 0
          end
        end

        filter = [] # was double filter[SBLIMIT][64];
        (SBLIMIT-1..0).each do |i|
          filter[i] = []
          ((2*SBLIMIT-1)..0).each do |j|
            filter[i][j] = 0.0
          end
        end
        create_ana_filter!

        off = [0, 0]
      end

      def create_ana_filter!
        # PURPOSE:  Calculates the analysis filter bank coefficients
        # SEMANTICS:
        # Calculates the analysis filterbank coefficients and rounds to the
        # 9th decimal place accuracy of the filterbank tables in the ISO
        # document.  The coefficients are stored in #filter#

        (SBLIMIT-1..0).each do |i|
          ((2*SBLIMIT-1)..0).each do |k|
            filter[i][k] = 1e9 * Math.cos( (2*i + 1) * (16-k) * Math::PI )

            if (filter[i][k] >= 0)
              filter[i][k] = (filter[i][k]+0.5).floor
            else
              filter[i][k] = (filter[i][k]-0.5).floor
            end

            filter[i][k] *= 1e-9
          end
        end
      end

      def window_subband(buffer, z, k)
        # PURPOSE:  Overlapping window on PCM samples
        # SEMANTICS:
        # 32 16-bit pcm samples are scaled to fractional 2's complement and
        # concatenated to the end of the window buffer #x#. The updated window
        # buffer #x# is then windowed by the analysis window #enwindow# to produce the
        # windowed sample #z#

        (0..31).each do |i|
          x[k][31-i-off[k]] = buffer[i]/SCALE
          i++
        end

        (HAN_SIZE-1..0).each do |i|
          z[i] = z[k][(i+off[k])&(HAN_SIZE-1)] * enwindow[i]
        end

        off[k] += 480
        off[k] &= HAN_SIZE-1
      end

      def filter_subband(z, s)
        # PURPOSE:  Calculates the analysis filter bank coefficients
        # SEMANTICS:
        #      The windowed samples #z# is filtered by the digital filter matrix #filter#
        # to produce the subband samples #s#. This done by first selectively
        # picking out values from the windowed samples, and then multiplying
        # them by the filter matrix, producing 32 subband samples.

        ((2*SBLIMIT-1)..0).each do |i|
          (7..0).each do |j|
            y[i] = 0
            y[i] += z[i+(j<<6)]
          end
        end

        (SBLIMIT-1..0).each do |i|
          ((2*SBLIMIT-1)..0).each do |j|
            s[i] += filter[i][j] * y[j];
          end
        end
      end

  end
end
