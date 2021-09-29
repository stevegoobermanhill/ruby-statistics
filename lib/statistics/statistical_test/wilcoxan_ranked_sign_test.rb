module Statistics
  module StatisticalTest
    class WilcoxonRankSignTest

    # Perform the calculation from list of rank pairs
    # method based on https://www.statstutor.ac.uk/resources/uploaded/wilcoxonsignedranktest.pdf

    def perform(alpha, tails, pairs)
        #remove pairs with the same rank
        pruned_pairs = pairs.delete_if{|x,y| x==y}
        
        #group size
        n = pruned_pairs.size.to_f

        rank_diffs = pruned_pairs.map {|x,y| y - x }
        signs = rank_diffs.map {|x| x>0 ? 1 : -1 }

        #rank the absolute diff sizes
        #first add an index (so we can recover the original order)
        #then sort by rank diff
        #then add the rsulting rank order to forma a triplet
        abs_rank_diffs = rank_diffs.map {|x| x.abs }
        ard_ranks = abs_rank_diffs.map
                                  .each_with_index{|x,i| [x,i] }
                                  .sort_by{|x| x[0]}
                                  .map
                                  .each_with_index{|x,i| x << i+1 }
        
        #where there are ties, replace each tied value with the average
        ard_rank_buckets = ard_ranks.group_by{|x| x[0]}
        ard_averaged = ard_rank_buckets.values.map do |a|
            avg = a.map{|x| x[2]}.reduce(:+).to_f/a.size
            a.map{|x| [avg, x[1]] }
        end

        #there is a varience correction factor for ties which we will use in the calculation
        #of the expected normal distribution we test against
        corrections = ard_rank_buckets.values.map do |a|
            t =  a.size
            t.pow(3) - t
        end
        total_correction = corrections.reduce(:+) / 48

        #return to orginal_order and extract calculated ranks
        ard_final_ranks = ard_averaged.reduce(:+).sort_by{|x| x[1]} 
        ranks = ard_final_ranks.map{|x| x[0]}


        #pair ranks with signs, partition by sign and sum
        sign_rank_pairs = signs.zip(ranks)
        w_plus_pairs, w_minus_pairs = sign_rank_pairs.partition{|x| x[0] == 1}
        w_plus = w_plus_pairs.map{|x| x[1]}.reduce(:+)
        w_minus = w_minus_pairs.map{|x| x[1]}.reduce(:+)

        w = [w_plus, w_minus].max

        #now calculate a normal distribution based on the group_size
        median_w = n * (n+1) / 4
        std_w = Math.sqrt(n * (n+1) * (2 * n + 1) / 24 - total_correction)

        # calculate z stat
        z = (w-median_w) / std_w

        # Most literature are not very specific about the normal distribution to be used.
        # We ran multiple tests with a Normal(median_u, std_u) and Normal(0, 1) and we found
        # the latter to be more aligned with the results.
        probability = Distribution::StandardNormal.new.cumulative_function(z.abs)
        p_value = 1 - probability
        p_value *= 2 if tails == :two_tail

        { probability: probability,
          w: w,
          z: z,
          p_value: p_value,
          alpha: alpha,
          null: alpha < p_value,
          alternative: p_value <= alpha,
          confidence_level: 1 - alpha }
    end

    end
  end
end
