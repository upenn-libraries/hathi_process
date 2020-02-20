#!/usr/bin/env ruby

require 'digest'
require 'time'
require 'open-uri'
require 'fileutils'
require 'nokogiri'
require 'optparse'

def missing_args?
  return (ENV['ALMA_KEY'].nil?)
end

def parse_manifest(lines_array)
  location_index = lines_array.index{|l| l.start_with?('location')}
  location = lines_array[location_index].chomp
  location = location.split('|').last
  lines_array.delete_at(location_index)

  destination_index = lines_array.index{|l| l.start_with?('destination')}
  destination = lines_array[destination_index].chomp
  destination = destination.split('|').last

  lines_array.delete_at(destination_index)

  return location, destination
end

def fetch_and_transform(string_to_parse)
  ark_replacements = {':' => '+',
                      '/' => '='}
  ark_id, bib_id = string_to_parse.chomp.split('|')
  directory = "#{ark_id}"
  ark_replacements.each do |key, value|
    directory.gsub!(key,value)
  end
  return ark_id, directory, bib_id
end

def duplicate_record_for_ark(ark_id, doc_s, field_to_search)
  doc_s.xpath(field_to_search).children.each do |child|

    if child.text != ark_id && child.text.start_with?('ark')
      child.parent.remove
    end

  end
  return doc_s.search('//record/*').to_xml
end

def write_marc_xml(write_location, ids)
  bibs_url = 'https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs'
  alma_key = ENV['ALMA_KEY']

  metadata_directory = 'metadata'
  metadata_location = FileUtils::mkdir_p("#{write_location}/#{metadata_directory}").first
  multivolume_field = '//datafield[@tag="965"]'

  records_processed = 0

  builder = Nokogiri::XML::Builder.new do |xml|
    xml['marc'].collection('xmlns:marc' => 'http://www.loc.gov/MARC21/slim', 'xmlns:xsi'=> 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd') {
      ids.each do |id|
        ark_id, bib_id = id.chomp.split('|')
        puts "Fetching MARC XML for #{ark_id}, saving to #{metadata_location}"

        marc_xml = ''
        path = "#{bibs_url}/#{bib_id}?apikey=#{alma_key}"

        begin
          open(path) { |io| marc_xml = io.read }
        rescue => exception
          return "#{exception.message} returned by source for #{bib_id}"
        end

        doc = Nokogiri::XML(marc_xml)
        doc.remove_namespaces!
        doc_s = doc.xpath('//record')

        if doc_s.xpath(multivolume_field).length > 1
          xml['marc'].record {
            xml << duplicate_record_for_ark(ark_id, doc_s, multivolume_field)
          }
        else
          xml['marc'].record {
            xml << doc_s.search('//record/*').to_xml
          }
        end

        records_processed += 1

      end

    }

  end

  file_name = "PU-2_#{Time.new.strftime('%Y%m%d')}_file1"

  File.open("#{metadata_location}/#{file_name}.xml", 'w+') do |xml|
    xml << (builder.to_xml)
  end

  return "#{metadata_location}/#{file_name}.xml", records_processed

end

def generate_marc_email(file_location, file_name, records_count)
  email_address = 'katherly@upenn.edu'
  file_size = File.size(file_location)

  send_to = 'Send to: cdl-zphr-l@ucop.edu'
  subject = 'Subject: Zephir metadata file submitted'
  body = "file name=#{file_name}\nfile size=#{file_size}\nrecord count=#{records_count}\nnotification email=#{email_address}"

  return "\n\n\n#{send_to}\n#{subject}\n\n#{body}\n\n\n"
end

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: hathi_ocr.rb [options]'

  opts.on('-b', '--[no-]ocr', 'Do not generate OCR (use boilerplate text)') do |b|
    options[:no_ocr] = b
  end

  opts.on('-m', '--metadata-only', 'Fetch MARC XML only') do |m|
    options[:metadata_only] = m
  end

end.parse!

organization = 'Schoenberg Center for Electronic Text and Image'
dpi_setting = '400'
order = ARGV[1] || 'left-to-right'

abort('Please supply a directory/bib id listing file like so:
ruby hathi_ocr.rb LISTING_FILE') if ARGV[0].nil?

file = ARGV[0]

abort("#{file} not found") unless File.exist?(file)

lines = File.open(file).readlines
location, destination = parse_manifest(lines)

if options[:metadata_only]
  return 'Missing Alma key' if missing_args?
  xml_file_path, records_processed = write_marc_xml(destination, lines)
  puts generate_marc_email(xml_file_path, File.basename(xml_file_path), records_processed)
else
  lines.each do |line|
    boilerplate_non_ocr_text = 'Image text could not be captured.'
    directory, bib_id = fetch_and_transform(line)
    
    FileUtils.mkdir_p(destination) unless File.exist?(destination)
    FileUtils.mkdir_p(directory) unless File.exist?(directory)

    puts "No scanning/reading order supplied, using default \"#{order}\"" if ARGV[1].nil?

    images = Dir.glob("#{directory}/*.jp2")

    images.each do |image|
      puts image
      if options[:no_ocr]
        File.open("#{directory}/#{File.basename(image,'.jp2')}.txt", 'w') { |f| f.write(boilerplate_non_ocr_text) }
      else
        `tesseract #{image} #{directory}/#{File.basename(image,'.jp2')}`
        `tesseract #{image} #{directory}/#{File.basename(image,'.jp2')} hocr`
      end
    end

    Dir.glob("#{directory}/*.hocr").each {|f| File.rename(f, f.gsub('hocr', 'html'))}

    meta_file = File.new("#{directory}/meta.yml", "w")

    meta_file.puts("capture_date: #{Time.now.iso8601}")
    meta_file.puts("scanner_user: #{organization}")
    meta_file.puts("contone_resolution_dpi: #{dpi_setting}")
    meta_file.puts("scanning_order: #{order}")
    meta_file.puts("reading_order: #{order}")

    meta_file.close

    all_files = Dir.glob("#{directory}/*.{jp2,txt,html,yml,xml}")

    all_files.sort_by!{|file| file.downcase}

    checksums_file = File.new("#{directory}/checksum.md5", "w")

    all_files.each do |file|
      checksums_file.puts("#{Digest::MD5.file(file).hexdigest} #{file.split("/").last}\n")
    end

    checksums_file.close

    zip_name = "#{File.basename(directory)}.zip"

    `zip -r -j #{destination}/#{zip_name} #{directory}/*`

  end

end
