$LOAD_PATH.unshift(".")

require 'pg'
require 'aws-sdk'
require 'beachball'

def main
  print "Updating sermon series ACLs "
  series_beachball = Beachball.new(10)
  series_beachball.start

  db.exec("select graphic_key, buy_graphic_key from sermon_series").each do |row|
    make_public_readable(row["graphic_key"], row["buy_graphic_key"])
  end

  print "\b"
  series_beachball.stop
  puts "\nFinished sermon series."

  print "Updating sermon ACLs "
  sermon_beachball = Beachball.new(10)
  sermon_beachball.start

  db.exec("select audio_key, buy_graphic_key from sermons").each do |row|
    make_public_readable(row["audio_key"], row["buy_graphic_key"])
  end

  sermon_beachball.stop
end

def s3
  return @s3 ||= Aws::S3::Resource.new(region: 'us-east-1')
end

def s3_object(key)
  s3.bucket('wisdomonline-development').object(key)
end

def make_public_readable(*keys)
  keys.each do |key|
    s3_object(key).acl.put({acl: "public-read"}) if s3_object(key)
  end
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
