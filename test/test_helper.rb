$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "collector"
require "collector/cli"

require "minitest/autorun"

module TranscriptTestHelpers
  def transcript_xml
    Nokogiri::XML.parse(File.read("test/fixtures/transcript.xml"))
  end
end
