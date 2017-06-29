$LOAD_PATH.unshift(".")

require 'pg'
require 'aws-sdk'

def main
  sermon_series_keys = db.exec("select graphic_key, buy_graphic_key from sermon_series")
  sermon_series_keys.each do |row|
    make_public_readable(row["graphic_key"], row["buy_graphic_key"])
  end
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
