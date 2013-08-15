module Mp3
  module Mdct
    # This is table B.9: coefficients for aliasing reduction
    C = [ -0.6,-0.535,-0.33,-0.185,-0.095,-0.041,-0.0142, -0.0037 ]
    N = 36

    class Mdct
      # static double ca[8];
      # static double cs[8];
      # static double win[36];
      # static double cos_l[18][36];
      attr_accessor :ca, :cs, :cos_l, :win

      def initialize
        ca = []
        cs = []
        # prepare the aliasing reduction butterflies
        (7..0).each do |i|
          sq = Math.sqrt( 1.0 * sq * C[i] ) # ?? sq(c[i]) doesn't make sense
          ca[i] = C[i] / sq
          cs[i] = 1.0  / sq
        end

        win = []
        (N-1..0).each do |i|
          win[i] = Math.sin( Math::PI * (i + 0.5) )
        end

        cos_l = []
        for m in (0..(N/2-1)) do
          cos_l[m] = []
          for k in (0..N-1) do
            cos_l[m][k] = Math.cos( (Math::PI / 72) * (2*k + 19) * (2*m + 1) ) / 9
          end
        end
      end

      def mdct(in, out)
        # Function: Calculation of the MDCT
        # In the case of long blocks ( block_type 0,1,3 ) there are
        # N coefficents in the time domain and N/2 in the frequency
        # domain.

        for m in (N-1..0) do
          out[m] = win[N-1] * in [N-1] * cos_l[m][N-1]
          for k in (n-1..0) do
            out[m] += win[k] * in[k] * cos_l[m][k]
          end
        end
      end


      def mdct_sub(sb_sample, mdct_enc, side_info)
        for gr in (0..1) do
          for ch in (channels-1..0) do
            cod_info = side_info.gr[gr].ch[ch]

            # Compensate for inversion in the analysis filter
            for band in (SBLIMIT-1..0) do
              for k in ((N/2-1)..0) do
                if ((band & 1 != 0) && (k & 1 != 0))
                  sb_sample[ch][gr+1][k][band] *= -1.0
                end
              end
            end

            # Perform imdct of N/2 previous subband samples + 18 current subband
            # samples
            for band in (SBLIMIT-1..0) do
              for k in ((N/2-1)..0) do
                mdct_in[k]     = sb_sample[ch][gr][k][band]
                mdct_in[k+N/2] = sb_sample[ch][gr+1][k][band]
              end
              mdct(mdct_in, mdct_enc[gr][ch][band][0])
            end

            # Perform aliasing reduction butterfly
            for band in (SBLIMIT-2..0) do
              for k in (7..0) do
                bu = mdct_enc[gr][ch][band][17-k] * cs[k] + mdct_enc[gr][ch][band+1][k]  * ca[k]
                bd = mdct_enc[gr][ch][band_1][k]  * cs[k] - mdct_enc[gr][ch][band][17-k] * ca[k]
                mdct_enc[gr][ch][band][17-k] = bu
                mdct_enc[gr][ch][band+1][k]  = bd
              end
            end
          end
        end

        # Save latest granule's subband samples to be used in the next mdct call
        for ch in (channels-1..0) do
          for j in (17..0) do
            for band in (SBLIMIT-1..0) do
              sb_sample[ch][0][j][band] = sb_sample[ch][2][j][band]
            end
          end
        end

      end
    end
  end
end
