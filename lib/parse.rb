require 'csv'

class DataParser
  def prepare_file!(params)
    path = export_filename
    File.open(path, 'w+') do |f|
      f.write "#{file_header(params)}\n"
      f.write parse(params[:tsv_data][:tempfile].read)
    end
    path
  end

  def export_filename
    "./tmp/teenshale_#{rand(8**8).to_s}.csv"
  end

  def parse(file_contents)
    # Setup
    all_lines = file_contents.split(/\r\n/).drop(1)
    dates = unique_days all_lines
    final_data = []

    # Crunch time
    dates.each do |day|
      row_data = {
        m_1: [], m_2: [], m_3: [], m_4: [], m_5: [], m_6: []
      }
      # We have to scan the whole file for each measurement from that day
      all_lines.each do |full_line|
        line = full_line.split /\t/
        line_day = parse_to_midnight(line.first)
        line[0] = line_day
        if day == line_day
          line.each_with_index do |value, key|
            row_data["m_#{(key.to_i + 1)}".to_sym].push value
          end
        end
      end
      if row_data[:m_1][0].is_a?(Time)
        row_data[:m_1] = row_data[:m_1][0]
      end
      [*2...6].each do |n|
        key = "m_#{n}".to_sym
        data = row_data[key]
        row_data[key] = average(data)
        row_data.delete(key) if data == "NaN" || data == [] || data.empty?
      end
      final_data.push row_data
    end

    # Create a CSV file with exported data
    file = CSV.generate do |csv|
      # Append each line of the final data to the CSV
      final_data.each do |hash|
        csv << hash.values
      end
    end

    final_lines = file.to_s.lines
    file = ""
    final_lines.each do |line|
      file += line.gsub(",[]", "")
    end

    file
  end

  protected

  # Find all the unique dates in the file
  def unique_days(all_lines)
    list = []
    all_lines.each do |line|
      list.push parse_to_midnight(line.split(/\t/).first)
    end
    list.uniq
  end

  def parse_to_midnight(dt)
    set_to_midnight Chronic.parse(dt)
  end

  def set_to_midnight(dt)
    dt.change({ hour: 0, min: 0, sec: 0 })
  end

  # Average an array of numbers
  def average(arr = [0])
    arr = arr.map(&:to_f).delete_if { |x| x < -900 }
    arr.inject { |s, e| s + e }.to_f / arr.size
  end

  def name_params(params)
    names = params.select { |key, value| key.to_s[/name_\d/] }
    names.values.reject(&:empty?).join(',').chomp(',')
  end

  def file_header(params)
    !name_params(params).empty? ? name_params(params) : 'Date,Temperature'
  end
end
