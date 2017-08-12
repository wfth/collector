require "pg"
require "aws-sdk"
require "fileutils"

module Collector::Command
  class UpdateTranscripts
    def initialize(storage, options)
      @storage = storage
    end

    def execute
      @storage.db.exec("select id, transcript_key from sermons").each do |row|
        if row["transcript_key"]
          transcript_file = Tempfile.new("#{row["id"]}-transcript.pdf")
          begin
            key = row["transcript_key"]
            @storage.s3_get_file(key, transcript_file.path)
            transcript = Collector::Transcript.new(transcript_file.path)
            @db.exec_params("update sermons set transcript_text = $1 where id = $2", [transcript.to_html, row["id"]])
          ensure
            transcript_file.close(true)
          end
        end
      end
    end
  end
end
