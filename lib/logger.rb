require "colorize"

module CustomLogger
  def log_header(msg)
    puts ""
    puts msg.blue
    puts "-" * msg.length
    puts ""
  end

  def log_plain_multiline(msg)
    lines = msg.lines
    lines.each do |line|
      puts "    " + line
    end
  end

  def log_info(msg)
    puts prefix_unless_empty(msg, "  - ").yellow
  end

  def log_error(msg)
    puts prefix_unless_empty(msg, "  - ").red
  end

  def log_success(msg)
    puts prefix_unless_empty(msg, "  - ").green
  end

  private

  def prefix_unless_empty(msg, prefix)
    msg.empty? ? "" : prefix + msg
  end
end
