require 'rubygems'
require 'bundler/setup'
require 'active_support/core_ext'

class Subscription
  cattr_reader :beginning
  attr_accessor :interval, :start_date, :frequency
  attr_reader :residue

  @@beginning = Date.new(2014, 1, 1)

  def initialize(args)
    args.each { |k, v| instance_variable_set("@#{k}", v) unless v.nil? }
    @frequency ||= :daily

    @date_move_method = case @frequency
    when :daily
      :days
    when :monthly
      :months
    end

    compute_residue
  end

  def process_on?(date)
    residue_for_date(date) == @residue
  end

  def next_processing_date(from_date)
    from_date + ((@residue - residue_for_date(from_date)) % @interval).send(@date_move_method)
  end

  def next_n_processing_dates(n, from_date)
    first_next_processing_date = next_processing_date(from_date)
    0.upto(n - 1).map { |i| first_next_processing_date + (@interval * i).send(@date_move_method) }
  end

  private

  def residue_for_date(date)
    case @frequency
    when :daily
      (date - @@beginning).to_i % @interval
    when :monthly
      ((date.year - @@beginning.year) * 12 + (date.month - @@beginning.month)) % @interval
    end
  end

  def compute_residue
    @residue = residue_for_date(@start_date)
  end
end
