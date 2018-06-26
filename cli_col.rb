class String
  def black;          "\e[30m#{self}\e[0m" end
  def red;            "\e[31m#{self}\e[0m" end
  def green;          "\e[32m#{self}\e[0m" end
  def brown;          "\e[33m#{self}\e[0m" end
  def blue;           "\e[34m#{self}\e[0m" end
  def magenta;        "\e[35m#{self}\e[0m" end
  def cyan;           "\e[36m#{self}\e[0m" end
  def gray;           "\e[37m#{self}\e[0m" end

  def bg_black;       "\e[40m#{self}\e[0m" end
  def bg_red;         "\e[41m#{self}\e[0m" end
  def bg_green;       "\e[42m#{self}\e[0m" end
  def bg_brown;       "\e[43m#{self}\e[0m" end
  def bg_blue;        "\e[44m#{self}\e[0m" end
  def bg_magenta;     "\e[45m#{self}\e[0m" end
  def bg_cyan;        "\e[46m#{self}\e[0m" end
  def bg_gray;        "\e[47m#{self}\e[0m" end

  def bold;           "\e[1m#{self}\e[22m" end
  def italic;         "\e[3m#{self}\e[23m" end
  def underline;      "\e[4m#{self}\e[24m" end
  def blink;          "\e[5m#{self}\e[25m" end
  def reverse_color;  "\e[7m#{self}\e[27m" end
end

def colorify(text, color)
  if color == "black" then text = text.black end
  if color == "red" then text = text.red end
  if color == "green" then text = text.green end
  if color == "brown" then text = text.brown end
  if color == "blue" then text = text.blue end
  if color == "magenta" then text = text.magenta end
  if color == "cyan" then text = text.cyan end
  if color == "gray" then text = text.gray end

  if color == "bg_black" then text = text.bg_black end
  if color == "bg_red" then text = text.bg_red end
  if color == "bg_green" then text = text.bg_green end
  if color == "bg_brown" then text = text.bg_brown end
  if color == "bg_blue" then text = text.bg_blue end
  if color == "bg_magenta" then text = text.bg_magenta end
  if color == "bg_cyan" then text = text.bg_cyan end
  if color == "bg_gray" then text = text.bg_gray end

  if color == "bold" then text = text.bold end
  if color == "italic" then text = text.italic end
  if color == "underline" then text = text.underline end
  if color == "blink" then text = text.blink end
  if color == "reverse_color" then text = text.reverse_color end

  text
end

def highlighter(text, options)
  optarray = options.split(",")
  optarray.each do |color|
    text = colorify(text, color)
  end
  text
end
