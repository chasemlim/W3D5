require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_vals = params.values
    where_keys = params.keys.map.with_index { |k, idx| "#{k} = '#{where_vals[idx]}'" }.join(" AND ")

    #debugger
    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_keys}
    SQL
    result_arr = []
    result.each do |hsh|
      result_arr << self.new(hsh)
    end
    result_arr
  end
end

class SQLObject
  extend Searchable
end
