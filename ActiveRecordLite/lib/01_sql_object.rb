require 'byebug'
require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @columns if @columns

    @columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @columns = @columns[0].map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |value|
        self.attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    hsh = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    parse_all(hsh)
  end

  def self.parse_all(results)
    obj_arr = []
    results.each do |hsh|
      obj_arr << self.new(hsh)
    end
    obj_arr
  end

  def self.find(id)
    obj = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL
    return nil if obj.empty?
    self.new(obj.first)
  end

  def initialize(params = {})
    params.each do |a, v|
      raise "unknown attribute '#{a}'" unless self.class.columns.include?(a.to_sym)

      send("#{a}=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col| send(col) }
  end

  def insert
    col_names = self.class.columns
    question_marks = (['?'] * col_names.length).join(", ")
    question_marks = "(" + question_marks + ")"

    DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names.join(", ")})
      VALUES
        #{question_marks}
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.map { |col| "#{col} = ?" }.join(", ")
    # debugger
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
