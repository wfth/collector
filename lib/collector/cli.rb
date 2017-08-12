ENV['WFTH_COLLECTOR_AWS_PROFILE'] ||= 'wfth'
ENV['WFTH_COLLECTOR_BUCKET_NAME'] ||= 'wisdomonline-development'
ENV['WFTH_COLLECTOR_DB_NAME'] ||= 'collector_dev'

require "thor"
require "collector"

module Collector
  class CLI < Thor
    def self.storage_options
      option :profile, :type => :string, :default => ENV['WFTH_COLLECTOR_AWS_PROFILE'], desc: "AWS credentials profile"
      option :bucket, :type => :string, :default => ENV['WFTH_COLLECTOR_BUCKET_NAME'], desc: "Collector bucket name"
      option :dbname, :type => :string, :default => ENV['WFTH_COLLECTOR_DB_NAME'], desc: "Collector database name"
    end

    storage_options
    desc "archive", "Collects resources and places them into the archive"
    def archive
      require "collector/cli/archive"
      Archive.new(Storage.new(options), options).execute
    end

    option :input, :type => :string, :default => "transcript.pdf", desc: "Path to PDF input file"
    option :output, :type => :string, :default => "-", desc: "Path to HTML output file or '-' for STDOUT"
    desc "transcript", "Converts a transcript PDF to HTML"
    def transcript
      transcript = Collector::Transcript.new(options[:input])
      if options[:output] == "-"
        puts transcript.to_html
      else
        File.open(options[:output], "w") { |f| f.puts transcript.to_html }
      end
    end

    storage_options
    desc "update-transcripts", "Process transcript PDFs to update HTML"
    def update_transcripts
      UpdateTranscripts.new(Storage.new(options), options).execute
    end

    storage_options
    option :table, :type => :string, :required => true, desc: "Resource table name"
    option :column, :type => :string, :required => true, desc: "S3 key column name"
    desc "update-acl", "Updates S3 resource ACL"
    def update_acl
      UpdateAcl.new(Storage.new(options), options).execute
    end
  end
end
