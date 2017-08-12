require 'aws-sdk'

module Collector
  class Storage
    attr_reader :profile, :bucket, :dbname, :dbuser, :dbpassword

    def initialize(options)
      @profile = ENV["AWS_PROFILE"] = options[:profile]
      @bucket = options[:bucket]
      @dbname = options[:dbname]
      @dbuser = options[:dbuser]
      @dbpassword = options[:dbpassword]
    end

    def s3_bucket
      @s3_bucket ||= begin
        s3 = Aws::S3::Resource.new(region: 'us-east-1')
        s3.bucket(bucket)
      end
    end

    def s3_delete_file(key)
      s3_bucket.object(key).delete if key
    end

    def s3_put_file(key, path, acl: "public-read")
      obj = s3_bucket.object(key)
      obj_status = obj.upload_file(path)
      obj.acl.put({acl: acl})
      obj.key if obj_status
    end

    def s3_get_file(key, path)
      obj = s3_bucket.object(key)
      obj.download_file(path)
    end

    def db
      unless @db
        begin
          @db = PG.connect(dbname: dbname, user: dbuser, password: dbpassword)
        rescue PG::ConnectionBad
          puts "Make sure the database '#{dbname}' exists!"
          exit(1)
        end

        @db.exec <<-SQL
          create table if not exists sermon_series (
            id SERIAL,
            a_id INTEGER UNIQUE,
            title TEXT NOT NULL,
            description TEXT,
            released_on TEXT,
            passages TEXT,
            graphic_key TEXT,
            graphic_source_url TEXT,
            buy_graphic_key TEXT,
            buy_graphic_source_url TEXT,
            price REAL
          );
        SQL

        @db.exec <<-SQL
          create table if not exists sermons (
            id SERIAL,
            title TEXT NOT NULL,
            description TEXT,
            passage TEXT,
            sermon_series_id INTEGER NOT NULL,
            audio_key TEXT,
            audio_source_url TEXT,
            transcript_key TEXT,
            transcript_source_url TEXT,
            transcript_text TEXT,
            buy_graphic_key TEXT,
            buy_graphic_source_url TEXT,
            price REAL
          );
        SQL
      end
    end
  end
end
