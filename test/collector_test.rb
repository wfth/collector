require "test_helper"

class CollectorTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Collector::VERSION
  end
end
