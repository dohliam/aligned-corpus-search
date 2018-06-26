#!/usr/bin/ruby -KuU
# encoding: utf-8

# Simple aligned corpus search tool with support for
# configurable context, regular expressions, frequency
# counting, and plain text output.
# 
# Usage (single file):
# ./aligned.rb [options] -i [INPUT_FILE]
# 
# Usage (all files in directory):
# ./aligned.rb [options] -d [DIRECTORY]

require 'optparse'

require_relative 'cli_col.rb'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: aligned.rb [options] -i [INPUT_FILE]"

  opts.on("-c", "--context CONTEXT", "Specify amount of surrounding context (in characters)") { |v| options[:context] = v }
  opts.on("-C", "--count-collocations", "Print a count of all collocated characters (together with -N or -P, and optionally -c)") { options[:count_collocations] = true }
  opts.on("-d", "--directory DIRECTORY", "Specify source directory") { |v| options[:directory] = v }
  opts.on("-h", "--half-width", "Use half-width spacing for alignment") { options[:half_width] = true }
  opts.on("-H", "--highlight-color OPTIONS", "Specify highlight, foreground, and background text colors") { |v| options[:highlight] = v }
  opts.on("-i", "--input-file FILE", "Specify input file") { |v| options[:input_file] = v }
  opts.on("-k", "--keyword KEYWORD", "Specify keyword to search for") { |v| options[:keyword] = v }
  opts.on("-K", "--keyword-frequency", "Show only matching keywords arranged in order of frequency") { options[:keyfreq] = true }
  opts.on("-N", "--collocated-next", "Print sorted list of collocations (following)") { options[:collocated_next] = true }
  opts.on("-p", "--plain-text", "Output plain text without highlighting") { options[:plain_text] = true }
  opts.on("-P", "--collocated-previous", "Print sorted list of collocations (preceding)") { options[:collocated_previous] = true }

end.parse!

def file_search(text, options)
  if options[:count_collocations]
    count_collocations(text, options)
  elsif options[:collocated_next]
    print_collocations(text, options)
  elsif options[:keyfreq]
    print_keyfreq(text, options)
  else
    print_matches(text, options)
  end
end

def directory_search(dir, options)
  if options[:count_collocations]
    dir_count_collocations(dir, options)
  elsif options[:collocated_next] || options[:collocated_previous]
    dir_print_collocations(dir, options)
  elsif options[:keyfreq]
    dir_print_keyfreq(dir, options)
  else
    dir_print_matches(dir, options)
  end
end

def dir_print_matches(dir, options)
  files = Dir.glob(dir.gsub(/\/+$/, "") + "/*")
  sort_files = files.sort_by { rand }
  sort_files.each do |f|
    text = File.read(f)

    space = "　"
    if options[:half_width]
      space = " "
    end

    print_matches(text, options)
  end
end

def search_corpus(text, options)
  keyword = ""
  if options[:keyword]
    keyword = options[:keyword]
  else
    abort("  Please specify a search keyword (-k).")
  end

  context = 10
  if options[:context]
    context = options[:context].to_i
  end

  re = /(.{0,#{context}}#{keyword}.{0,#{context}})/

  matches = text.scan(re).flatten

  results = {}
  results[:matches] = matches
  results[:context] = context
  results[:keyword] = keyword

  results
end

def print_matches(text, options)
  results = search_corpus(text, options)

  matches = results[:matches]
  keyword = results[:keyword]
  context = results[:context]

  space = "　"
  if options[:half_width]
    space = " "
  end

  matches.each do |match|
    if match.match(/^\s*$/) then next end
    lead_len = 0
    if match != keyword
      lead_len = match.split(keyword)[0].length
    end
    if lead_len < 0
      lead_len = 0
    elsif lead_len > context
      lead_len = context
    end
    padding = space * (context - lead_len)
    if options[:plain_text]
      puts padding + match.gsub(/(#{keyword})/, "\t\\1\t")
    else
      colopts = "bold,red"
      if options[:highlight]
        colopts = options[:highlight]
      end
      puts padding + match.gsub(/(#{keyword})/, "\t" + highlighter("\\1", colopts) + "\t")
    end
  end
end

def print_collocations(text, options)
  results = search_corpus(text, options)

  matches = results[:matches]
  keyword = results[:keyword]
  context = results[:context]

  collector = []
  keyword = options[:keyword]
  matches.each do |match|
    if match.match(/^\s*$/) then next end
#     following = match.sub(/^.*?#{keyword}/, "")
    following = get_collocates(match, keyword, options)
    if !following.match(/^\s*$/)
      collector << following
    end
  end
  puts collector.sort
#   exit
end

def count_collocations(text, options)
  results = search_corpus(text, options)

  matches = results[:matches]
  keyword = results[:keyword]
  context = results[:context]

  freq = Hash.new(0)
  context = 1
  if options[:context]
    context = options[:context].to_i
  end
  matches.each do |match|
    if match.match(/^\s*$/) then next end
#     following = match.sub(/^.*?#{keyword}/, "").sub(/^(.{#{context}}).*/, "\\1")
    following = get_collocates(match, keyword, options)
    freq[following] += 1
  end
#   puts collector.sort

  freq.sort_by { |coll, num| num }.reverse.each {|s| puts s[0] + ": " + s[1].to_s}
#   freq.keys.sort.each {|k| a << k + "-" + freq[k].to_s + "\n"}
#   puts a.sort_by{|f| f.split("-")[1].to_i }

#   exit
end

def dir_count_collocations(dir, options)
  freq = Hash.new(0)

  files = Dir.glob(dir.gsub(/\/+$/, "") + "/*")
  files.sort.each do |f|
    text = File.read(f)

    results = search_corpus(text, options)

    matches = results[:matches]
    keyword = results[:keyword]

    context = 1
    if options[:context]
      context = options[:context].to_i
    end

    matches.each do |match|
      if match.match(/^\s*$/) then next end
#       following = match.sub(/^.*?#{keyword}/, "").sub(/^(.{#{context}}).*/, "\\1")
      following = get_collocates(match, keyword, options)
      freq[following] += 1
    end
  end

  freq.sort_by { |coll, num| num }.reverse.each {|s| puts s[0] + ": " + s[1].to_s}
end

def dir_print_collocations(dir, options)
  collector = []

  files = Dir.glob(dir.gsub(/\/+$/, "") + "/*")
  files.sort.each do |f|
    text = File.read(f)

    results = search_corpus(text, options)

    matches = results[:matches]
    keyword = results[:keyword]

    matches.each do |match|
      if match.match(/^\s*$/) then next end
      collocates = get_collocates(match, keyword, options)
      collector << collocates
    end
  end
  puts collector.sort
end

def get_collocates(match, keyword, options)
  collocates = ""
  context = 1
  if options[:context]
    context = options[:context].to_i
  end
  if options[:collocated_previous]
#     collocates = match.sub(/#{keyword}.*?$/, "")
    collocates = match.sub(/#{keyword}.*?$/, "").sub(/^(.{#{context}}).*/, "\\1")
  elsif options[:collocated_next]
    collocates = match.sub(/^.*?#{keyword}/, "").sub(/^(.{#{context}}).*/, "\\1")
#     collocates = match.sub(/^.*?#{keyword}/, "")
  end
  collocates
end

def print_keyfreq(text, options)
  results = search_corpus(text, options)

  matches = results[:matches]
  keyword = results[:keyword]
  context = results[:context]

  freq = Hash.new(0)
  matches.each do |match|
    if match.match(/^\s*$/) then next end
    colopts = "bold,blue"
    if options[:highlight]
      colopts = options[:highlight]
    end
    keymatch = match.sub(/.*?(#{keyword}).*/, highlighter("\\1", colopts))
    if options[:plain_text]
      keymatch = match.sub(/.*?(#{keyword}).*/, "\\1")
    end
    freq[keymatch] += 1
  end

  freq.sort_by { |coll, num| num }.reverse.each {|s| puts s[0] + ": " + s[1].to_s}
end

def dir_print_keyfreq(dir, options)
  freq = Hash.new(0)

  files = Dir.glob(dir.gsub(/\/+$/, "") + "/*")
  files.sort.each do |f|
    text = File.read(f)

    results = search_corpus(text, options)

    matches = results[:matches]
    keyword = results[:keyword]

    matches.each do |match|
      if match.match(/^\s*$/) then next end
      colopts = "bold,blue"
      if options[:highlight]
        colopts = options[:highlight]
      end
      keymatch = match.sub(/.*?(#{keyword}).*/, highlighter("\\1", colopts))
      if options[:plain_text]
	keymatch = match.sub(/.*?(#{keyword}).*/, "\\1")
      end
      freq[keymatch] += 1
    end
  end
  freq.sort_by { |coll, num| num }.reverse.each {|s| puts s[0] + ": " + s[1].to_s}
end

dir = File.absolute_path(File.dirname(__FILE__) + "/data")

if options[:input_file]
  input_file = options[:input_file]
  text = File.read(input_file)
  file_search(text, options)
elsif options[:directory]
  dir = options[:directory]
  directory_search(dir, options)
elsif Dir.exist?(dir)
  directory_search(dir, options)
else
  abort("  Please specify an input file (-i) or directory (-d).")
end
