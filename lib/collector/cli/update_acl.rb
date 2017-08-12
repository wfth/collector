require 'pg'
require 'aws-sdk'

module Collector::CLI
  class UpdateAcl
    attr_reader :table, :column

    def initialize(storage, options)
      @storage = storage
      @table, @column = options[:table], options[:column]
    end

    def execute
      @storage.db.exec("select id, #{column} from #{table}").each do |row|
        obj = @storage.s3_object(row[column])
        if obj && obj.exists?
          puts "Updating ACL: #{table}.#{column}##{row["id"]} #{row[column]}"
          obj.acl.put({acl: "public-read"})
        else
          puts "! Missing: #{table}.#{column}##{row["id"]} #{row[column]}"
        end
      end
    end
  end
end
