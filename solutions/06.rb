module TurtleGraphics
  class Turtle
    def initialize(height, width)
      @height = height
      @width = width
      @canvas = Array.new(height).map! {Array.new(width, 0)}
      @canvas[0][0] = 1
      @current_position = [0,0]
      @orientation = :right
      self
    end

    def define_which_sign(intensity, coefficient, ascii, drawing)
      count = 1
      length = ascii.length
      while count < length
        previous_sign = (count - 1) * coefficient
        next_sign = (count + 1) * coefficient
        if intensity >= previous_sign and intensity < next_sign
          drawing << ascii[count]
          count += 1
        end
        count += 1
      end
    end

    def draw_ascii(length, ascii, &block)
      self.instance_eval(&block)
      drawing, max_intensity = "", (@canvas.max { |a,b| a.max <=> b.max }).max
      @canvas.each do |row|
        row.each do |element|
          intensity, coefficient = (element.to_f) / max_intensity, 1.0 /(length - 1)
          pick_sign(intensity, coefficient, ascii, drawing)
          end
        drawing << "\n"
        end
      drawing.chop
    end

    def pick_sign(intensity, coefficient, ascii, drawing)
      if intensity == 0
        drawing << ascii[0]
      else define_which_sign(intensity, coefficient, ascii, drawing)
      end
    end

    def draw(ascii = nil, &block)
      if ascii
        draw_ascii(ascii.length, ascii, &block)
      else  self.instance_eval(&block)
        @canvas
      end
    end

    def move
      moves = {right: [0, 1], left: [0, -1], up: [-1, 0], down: [1, 0]}
      new_row = (@current_position[0] + moves[@orientation][0]) % @height
      new_column = (@current_position[1] + moves[@orientation][1]) % @width
      @canvas[new_row][new_column] += 1
      @current_position = [new_row, new_column]
    end

    def turn_left
      case @orientation
        when :up then @orientation = :left
        when :down then @orientation = :right
        when :left then @orientation = :down
        when :right then @orientation = :up
      end
    end

    def turn_right
      case @orientation
        when :up then @orientation = :right
        when :down then @orientation = :left
        when :left then @orientation = :up
        when :right then @orientation = :down
      end
    end

    def spawn_at(row, column)
      @canvas[0][0] = 0
      @current_position[0] = row
      @current_position[1] = column
      @canvas[row][column] += 1
    end

    def look(orientation)
      @orientation = orientation
    end
  end

  module Canvas
    class ASCII
      attr_reader :length
      def initialize(list_of_symbols)
        @symbols = Array.new (list_of_symbols)
        @length = list_of_symbols.length
      end

      def [] (number)
        @symbols[number]
      end
    end

    class HTML
      def initialize(size)
      end
    end
  end
end
