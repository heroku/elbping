
require 'test/unit'
require 'elbping/resolver.rb'

DEFAULT_NS = ENV['TEST_NS'] || 'ns-941.amazon.com'
DEFAULT_GOOD_ELB = ENV['TEST_GOOD_ELB'] || 'test-elb-868888812.us-east-1.elb.amazonaws.com' # feels dirty

class TestResolver< Test::Unit::TestCase
  def test_bad_queries
    ["fake.amazonaws.com", "google.com", "nxdomain.asdf"].each { |tgt|
      assert_equal [], ElbPing::Resolver.find_elb_nodes(tgt, DEFAULT_NS)

      # I think something internal to Resolv is returning nil in tcp mode
      #assert_raise Timeout::Error do
      #  ElbPing::Resolver.find_elb_nodes(tgt, DEFAULT_NS)
      #end
    }
  end

  # This might still fail from time to time :-\ Been seeing lots of failures to connect to AWS DNS
  def test_good_query
    resp = nil
    assert_nothing_raised do
      resp = ElbPing::Resolver.find_elb_nodes(DEFAULT_GOOD_ELB, DEFAULT_NS)
    end
    # I don't actually care what the results are, only that they are a list
    assert_equal resp.class, Array
  end
end

