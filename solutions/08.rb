module Sheet
  def fill_sheet(data, sheet, i, current)
    while i < data.size
      fill(data, sheet, current, i)
    end
    sheet << current
  end

  def fill(data, sheet, current,i)
    last = data[i - 1]
    if (data[i] == " " and last == " ") || data[i] == "\t" || data[i] == "\n"
      sheet << current if current != " "
      current, last, i = "", data[i], i + 1
    else current, last, i = current + data[i],data[i], i + 1
    end
  end

  def index_numbers(cell_index)
    index_array, numbers = cell_index.chars, ""
    while index_array.empty? == false
      if index_array[0].ord > 47 && index_array[0].ord < 58
        numbers += index_array[0]
      end
      index_array.shift
    end
    numbers
  end

  def transform(letters, index)
    while letters.empty? == false
      if letters.size == 1
        index += letters[0].ord - 64
      else index += 26 * (letters[0].ord - 64)
      end
      letters.shift
    end
    index
  end
end

class Spreadsheet
  include Sheet
  attr_accessor :sheet, :data
  def initialize(data = nil)
    @data = data.strip if data
    columns = count_columns(data)
    temp = []
    @sheet = fill_sheet(@data, temp, 1, @data[0]).each_slice(columns).to_a
  end


  def empty?
    if @data == nil || @data == ""
      true
    else false
    end
  end

  def cell_at(cell_index)
    letters, numbers = index_letters(cell_index), index_numbers(cell_index)
    letters = transform(letters.chars, 0)
    @sheet[letters - 1][numbers - 1]
  end

  def []
  end

  def count_columns(sheet)
    columns, index, previous = 1, 1, sheet[0]
    while sheet[index] != "\n"
      columns += 1 if sheet[index] == "\t"
      columns += 1 if sheet[index] == " " and previous == " "
       previous, index = sheet[index -  1], index + 1
    end
    columns
  end
end
