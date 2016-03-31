require 'csv'
require 'pry'

class DataParser
  def prepare_data(params)
    parse params[:tsv_data][:tempfile].read
  end

  def prepare_file!(filename = "", data)
    File.open(filename, "w") do |f|
      f.write "Date,Low range,Temperature\n"
      f.write data
    end
  end

  def export_filename
    "./tmp/teenshale_export_#{rand(8**8).to_s}.csv"
  end

  def parse(file_contents)
    # Boring setup
    all_lines = file_contents.split /\r\n/
    dates = unique_days all_lines
    final_data = []

    # Crunching time
    dates.each do |day|
      measurements_low_range = []
      measurements_temp = []
      # We have to scan the whole file for each measurement from that day
      all_lines.each do |line|
        if line.match day[2...10]
          info = line.split /\t/
          measurements_low_range.push info[1].to_f
          measurements_temp.push info[2].to_f
        end
      end
      # Create a hash with the date and averaged measurements
      item = {
        date: Chronic.parse(day),
        low_range: average(measurements_low_range),
        temp: average(measurements_temp)
      }
      final_data.push item
    end

    # Create a CSV file with exported data
    file_export = CSV.generate do |csv|
      # Append each line of the final data to the CSV
      final_data.each do |hash|
        csv << hash.values
      end
    end

    file_export
  end

  protected

  # Find all the unique dates in the file
  def unique_days(all_lines)
    all_dates = []
    unique_dates = []
    # Find and remember all the unique dates data was recorded
    all_lines.each do |line|
      info = line.split /\t/
      # Equipment omits the "20" before the year. Chronic needs it.
      all_dates.push "20#{info[0]}"
    end
    all_dates.each do |date|
      day = date[0...10]
      unique_dates.push day unless unique_dates.include? day
    end
    unique_dates
  end

  def rounded(num = 0)
    "%.2f" % num.to_f
  end

  # Method to quickly average an array of numbers
  def average(arr = [0])
    avg = arr.inject { |sum, el| sum + el }.to_f / arr.size
    rounded avg
  end
end
