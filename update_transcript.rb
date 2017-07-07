$LOAD_PATH.unshift(".")

require "pg"
require "aws-sdk"
require "fileutils"

def main
  add_transcript_text_column

  sermon_transcripts = db.exec("select id, transcript_key from sermons")
  for transcript in sermon_transcripts
    if transcript["transcript_key"]
      key = transcript["transcript_key"]
      s3.get_object({ bucket: "wisdomonline-development", key: key }, target: "transcript.pdf")
      transcript_text = `ruby extract_text_from_transcript.rb transcript.pdf`
      @db.exec_params("update sermons set transcript_text = $1 where id = $2", [transcript_text, transcript["id"]])
      FileUtils.rm "transcript.pdf", :force => true
    end
  end
end

def s3
  @s3 ||= Aws::S3::Client.new
end

def db
  @db ||= PG.connect(dbname: "collector_dev", user: "postgres", password: "postgres")
end

def add_transcript_text_column
  begin
    db.exec("ALTER TABLE sermons ADD COLUMN transcript_text TEXT")
  rescue
  end
end

main()
