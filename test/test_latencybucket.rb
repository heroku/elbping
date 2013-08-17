require 'test/unit'
require 'elbping/latency_bucket.rb'

class TestLatencyBucket < Test::Unit::TestCase
  def test_init
    bucket = nil
    assert_nothing_raised do
      bucket = LatencyBucket.new
      assert_not_nil bucket
      bucket << 1
      bucket << 2
    end
    assert_equal bucket.to_a, [1, 2]
  end
  def test_sum
    bucket = LatencyBucket.new
    bucket << 0
    assert_nothing_raised do
      assert_equal bucket.sum, 0
    end
    bucket << 100
    bucket << 200
    bucket << 300
    bucket << 3
    assert_equal bucket.sum, (0 + 100 + 200 + 300 + 3)
  end
  def test_mean
    bucket = LatencyBucket.new
    bucket << 100
    bucket << 200
    bucket << 300
    bucket << 0
    bucket << 3
    assert_equal bucket.mean, ((100 + 200 + 300 + 0 + 3)/5).to_i
  end
  def test_mean_divide_by_zero
    bucket = LatencyBucket.new
    assert_nothing_raised do
      assert_equal bucket.mean, 0
    end
  end
end
