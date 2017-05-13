#!/usr/bin/env ruby

# Given a file of raw PCM audio data (sans header),
# create the associated WAVE header and write out an 
# entire new , valid WAVEfile (header + data).
#
# Based on info from http://soundfile.sapp.org/doc/WaveFormat/

# You can change the following based on the raw data:

numchannels = 1
sampleratehz = 8000
bitspersample = 16

require 'bindata'

def usage(error)
  puts "Error: #{error}" unless error.nil?
  puts "#{$0}: <raw wave data input file> <output filename>"
end

infile = ARGV[0]
unless infile
  usage "specify an input file"
  exit
end
outfile = ARGV[1]
unless outfile
  usage "specify an output file"
  exit
end

infd = File.open(infile, 'rb')
unless infd
  puts "Error: failed to open file '#{infile}' for reading."
  exit
end
outfd = File.open(outfile, 'wb')
unless outfd
  puts "Error: failed to open file '#{outfile}' for writing."
  exit
end

datasize = infd.size
subchunk1size = 16
chunksize = 4 + (8 + subchunk1size) + (8 + datasize)
byterate = sampleratehz * numchannels * bitspersample / 8
blockalign = numchannels * bitspersample / 8

BinData::Int32be.new(0x52494646).write(outfd)    # ChunkID: "RIFF"
BinData::Int32le.new(chunksize).write(outfd)     # ChunkSize
BinData::Int32be.new(0x57415645).write(outfd)    # Format: "WAVE"
BinData::Int32be.new(0x666d7420).write(outfd)    # SubChunk1ID: "fmt "
BinData::Int32le.new(16).write(outfd)            # SubChunk1Size
BinData::Int16le.new(1).write(outfd)             # AudioFormat
BinData::Int16le.new(numchannels).write(outfd)   # NumChannels
BinData::Int32le.new(sampleratehz).write(outfd)  # SampleRate
BinData::Int32le.new(byterate).write(outfd)      # ByteRate
BinData::Int16le.new(blockalign).write(outfd)    # BlockAlign
BinData::Int16le.new(bitspersample).write(outfd) # BitsPerSample
BinData::Int32be.new(0x64617461).write(outfd)    # SubChunk2ID: "data"
BinData::Int32le.new(datasize).write(outfd)      # SubChunk2Size

loop do
  chunk = infd.read(1024)
  outfd.write(chunk)
  break if infd.eof?
end

infd.close()
outfd.close()

puts "Done!"
