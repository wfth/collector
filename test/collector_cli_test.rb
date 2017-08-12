require "test_helper"

class CollectorCLITest < Minitest::Test
  def test_load_cli
    refute_nil ::Collector::CLI
  end
end
