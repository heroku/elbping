require 'test/unit'
require 'elbping/stats.rb'

class TestStats < Test::Unit::TestCase

  STATS_KEYS = [:requests, :responses, :latencies]
  TEST_NODES = ["1.1.1.1", "2.2.2.2", "3.3.3.3"]

  def test_always_pass
    assert_equal true, true
  end

  def test_init
    stats = nil
    assert_nothing_raised do
      stats = ElbPing::Stats.new
    end
    assert_not_nil stats

    # Validate stats.total
    assert_equal stats.total.class, Hash

    STATS_KEYS.each do |key|
      assert_equal stats.total.keys.include?(key), true
    end

    # Validate stats.nodes
    assert_equal stats.nodes.class, Hash
    assert_equal stats.nodes.size, 0
  end

  def test_add_node
    stats = ElbPing::Stats.new

    TEST_NODES.each do |node|
      assert_nothing_raised do
        stats.add_node node
      end
      assert_equal stats.nodes.keys.include?(node), true
      STATS_KEYS.each do |key|
        assert_equal stats.nodes[node].keys.include?(key), true
      end
    end
  end

  # TODO: Make this more maintainable
  def test_register
    ping_statuses = [
      {:code => 200, :exception => nil, :node => "1.1.1.1", :duration => 100},
      {:code => 400, :exception => nil, :node => "2.2.2.2", :duration => 100},
      {:code => 405, :exception => nil, :node => "1.1.1.1", :duration => 100},
      {:code => 302, :exception => nil, :node => "2.2.2.2", :duration => 100},
      {:code => :timeout, :exception => nil, :node => "1.1.1.1", :duration => 100},
      {:code => :econnrefused, :exception => nil, :node => "2.2.2.2", :duration => 100},
      {:code => :exception, :exception => "TEST", :node => "1.1.1.1", :duration => 100},
    ]
    
    stats = ElbPing::Stats.new
    ping_statuses.each do |status|
      stats.register status
    end

    assert_equal stats.total[:requests], ping_statuses.size
    assert_equal stats.total[:responses], 4
    assert_equal stats.total[:latencies].size, 4
    assert_equal stats.total_loss, (1 - (4.to_f / ping_statuses.size))

    assert_equal stats.nodes.size, 2
    assert_equal stats.nodes.keys.include?("1.1.1.1"), true
    assert_equal stats.nodes.keys.include?("2.2.2.2"), true
    assert_equal stats.node_loss("1.1.1.1"), (1 - (2.to_f/4))
    assert_equal stats.node_loss("2.2.2.2"), (1 - (2.to_f/3))
  end
end

