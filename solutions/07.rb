module LazyMode
  def self.create_file(name, &block)
    object = File.new(name)
    object.instance_eval &block
    object
  end

  class Date
    def initialize(date)
      @date = date
      @day = date.split('-')[2].to_i
      @month = date.split('-')[1].to_i
      @year = date.split('-')[0].to_i
    end

    def year
      @year
    end

    def month
      @month
    end

    def day
      @day
    end

    def add_day
      if @day == 30 and @month == 12
        @day, @month = 1, 1
        @year += 1
      elsif @day == 30
        @day, @month = 1, @month + 1
      else @day += 1
      end
    end

    def to_s
      @date.split('-')[2].insert(0, '0') if @date.split('-')[2].length < 2
      @date.split('-')[1].insert(0, '0') if @date.split('-')[1].length < 2
      @date.split('-')[0].insert(0, '0') if @date.split('-')[0].length < 4
      @date
    end
  end

  class Note
    attr_accessor :file_name, :body, :status, :header, :date, :period
    def initialize(header, *tags, status, body)
      @header = header
      @body = body
      @status = status
      @tags = *tags.flatten
      @file_name = ''
      @period = 0
    end

    def copy(date)
      object = Note.new(@header, @tags, @status, @body)
      object.date = date
      object
    end

    def tags
      @tags
    end
  end

  class MainNote
    attr_accessor :date, :all_notes
    def initialize(header, *tags)
      @header = header
      @tags = *tags.flatten
      @status = :topostpone
      @period = 0
    end

    def scheduled(period)
      date = period.split('+')
      @date = Date.new(date[0].chomp)
      @period = define_period(date) if date.size == 2
    end

    def note(header, *tags, &block)
      object = MainNote.new(header, *tags)
      object.all_notes = @all_notes
      object.instance_eval &block if block_given?
      note = object.return_note
      note.file_name = @name
      @all_notes.push(note)
    end

    def define_period(date)
      case date[1].chars.last
      when 'w' then date[1].chars.first.to_i * 7
      when 'd' then date[1].chars.first.to_i
      when 'm' then date[1].chars.first.to_i * 30
      end
    end

    def status(status)
      @status = status
    end

    def body(body)
      @body = body
    end

    def return_note
      object = Note.new(@header, @tags, @status, @body)
      object.date = @date
      object.period = @period
      object
    end
  end

  class File
    attr_accessor :all_notes
    attr_reader :name
    def initialize(name)
      @name = name
      @all_notes = []
    end

    def note(header, *tags, &block)
      object = MainNote.new(header, *tags)
      object.all_notes = @all_notes
      object.instance_eval &block if block_given?
      note = object.return_note
      note.file_name = @name
      @all_notes.push(note)
    end

    def notes
      @all_notes
    end

    def daily_agenda(date)
      DailyAgenda.new(date, @all_notes)
    end

    def weekly_agenda(date)
      WeeklyAgenda.new(date, @all_notes)
    end

    def where
    end
  end

  class Agenda
    def initialize(date, all_notes)
      @date = date
      @all_notes = all_notes
      @notes = []
    end

    def notes
      @all_notes.each { |note| check_dates(note.date, note) }
      @notes
    end

    def date_difference(date)
      year = (@date.year - date.year) * 360
      month = (@date.month - date.month) * 30
      day = (@date.day - date.day)
      year + month + day
    end

    def check_dates(date, note)
      if (note.period != 0) and date_difference(date) % note.period == 0
        @notes.push(note.copy(@date))
      end
    end
  end

  class DailyAgenda < Agenda
    def notes
      @all_notes.each { |note| check_dates(note.date, note) }
      @notes
    end
  end

  class WeeklyAgenda < Agenda
    def notes
      (0...7).each do
        @notes += DailyAgenda.new(@date, @all_notes).notes
        @date = @date.add_day
      end
      @notes
    end
  end
end
