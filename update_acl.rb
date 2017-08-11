ENV['AWS_PROFILE'] = 'wfth'

require 'pg'
require 'aws-sdk'

def main(table, column)
  db.exec("select id, #{column} from #{table}").each do |row|
    obj = s3_object(row[column])
    if obj && obj.exists?
      puts "Updating ACL: #{table}.#{column}##{row["id"]} #{row[column]}"
      obj.acl.put({acl: "public-read"})
    else
      puts "! Missing: #{table}.#{column}##{row["id"]} #{row[column]}"
    end
  end
end

def s3
  @s3 ||= Aws::S3::Resource.new(region: 'us-east-1')
end

def s3_object(key)
  s3.bucket('wisdomonline-development').object(key)
end

def db
  @db ||= PG.connect(dbname: "collector_dev", user: "postgres", password: "postgres")
end

main(ARGV[0], ARGV[1])
