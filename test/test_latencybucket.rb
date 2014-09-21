require 'test/unit'
require 'elbping/latency_bucket.rb'

class TestLatencyBucket < Test::Unit::TestCase
  def test_init
    bucket = LatencyBucket.new
    assert_not_nil bucket
    bucket << 1
    bucket << 2
    assert_equal bucket.to_a, [1, 2]
  end
  def test_sum
    bucket = LatencyBucket.new

    # bucket.sum should initialize to zero
    assert_equal bucket.sum, 0

    # and still
    bucket << 0
    assert_equal bucket.sum, 0
    bucket << 1
    assert_equal bucket.sum, 1
  end
  def test_mean
    bucket = LatencyBucket.new
    assert_equal bucket.mean, 0
    bucket << 2
    assert_equal bucket.mean, 2
    bucket << 2
    assert_equal bucket.mean, 2
    bucket << 8
    assert_equal bucket.mean, 4
  end
end
