require 'spec_helper'

describe Statistics::StatisticalTest::WilcoxonSignedRankTest do
  let(:test_class) { described_class.new }

  

  ## Examples
  # Example ONE extracted from https://www.statstutor.ac.uk/resources/uploaded/wilcoxonsignedranktest.pdf
  # Comparison of effectiveness of two analgesic drugs.
  

  describe '#perform' do
    it 'always computes the test approximating the z-statistic to the standard normal distribution' do
      expect_any_instance_of(Distribution::StandardNormal)
        .to receive(:cumulative_function).and_call_original

      result = test_class.perform(0.05, :two_tail, [[1,4],[5,3],[7,6]])

      expect(result.keys).to include :z
    end

    it 'performs a wilcoxon rank sum/Mann-Whitney U test following example ONE' do
      a= [2.0, 3.6, 2.6, 2.6, 7.3, 3.4, 14.9, 6.6, 2.3, 2.0, 6.8, 8.5]
      b = [3.5, 5.7, 2.9, 2.4, 9.9, 3.3, 16.7, 6.0, 3.8, 4.0, 9.1, 20.9]
      pairs = a.zip(b)

      result = test_class.perform(0.05, :two_tail, pairs)

      expect(result[:z].round(2)).to eq 2.51
      expect(result[:null]).to be false
      expect(result[:alternative]).to be true
      expect(result[:p_value].round(3)).to eq 0.012
    end
  end
end
