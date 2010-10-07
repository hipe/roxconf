#!/usr/bin/env ruby
require 'fileutils'

File.open('aha_people', 'r') do |fh|
  while line = fh.gets do
    line = line.strip
    want = "keydir/#{line}@hipeland.pub"
    have = "/home/#{line}/.ssh/id_rsa.pub"
    if File.exist?(want)
      left = File.read(want)
      rite = File.read(have)
      if left == rite
        puts "ok: #{line}"
      else
        puts "warning: not the same: #{want} #{have}"
      end
    else
      # FileUtils.cp(have, want, :verbose => 1, :noop => 1)
      FileUtils.cp(have, want, :verbose => 1)
    end
  end
end

