$LOAD_PATH.unshift(".")

require 'pg'
require 'aws-sdk'
require 'beachball'

def main
  print "Renaming all sermon transcripts "
  beachball = Beachball.new(10)
  beachball.start
  
  db.exec("select id, transcript_key from sermons").each do |row|
    next if !row["transcript_key"]
    new_key = update_title(row["transcript_key"])
    db.exec_params("update sermons set transcript_key = $1 where id = $2", [new_key, row["id"]])
  end

  beachball.stop
  print "\b"
  puts "\nFinished."
end

def update_title(key)
  begin
    obj = s3_object(key)
    obj.move_to("wisdomonline-development/#{key.gsub(/%20/, "-")}", {acl: "public-read", metadata_directive: "REPLACE"})
  rescue Aws::S3::Errors::NoSuchKey
    obj = s3_object(key.gsub(/%20/, "-"))
  end

  obj.key
end

def s3
  return @s3 ||= Aws::S3::Resource.new(region: 'us-east-1')
end

def s3_object(key)
  s3.bucket('wisdomonline-development').object(key)
end

def db
  unless @db
    initial_connection = PG.connect(user: "postgres", password: "postgres")

    begin
      @db = PG.connect(dbname: 'collector_dev', user: "postgres", password: "postgres")
    rescue
      puts "Please make sure the collector_dev Postgres database exists!"
      exit
    end
  end

  return @db
end

main()
