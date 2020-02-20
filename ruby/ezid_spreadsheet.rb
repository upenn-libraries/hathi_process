#!/usr/bin/ruby

require 'rubyXL'
require 'ezid-client'

def missing_args?
  return (ARGV[0].nil?) || (ARGV[1].nil?)
end

def set_headers(worksheet, headers_hash)
  headers_hash.each_with_index do |(key, value), index|
    worksheet.add_cell(0,index, value)
  end
end


def mint_arkid(erc_information)
  identifier = Ezid::Identifier.mint(erc_information)
  return identifier
end

workbook = RubyXL::Workbook.new

def workbook.set_up_spreadsheet
  worksheet = worksheets[0]
  worksheet.sheet_name = 'hathi_batch'
  set_headers(worksheet, HEADERS)
end

def workbook.populate(dataset)
  source_worksheet = dataset[0]
  worksheet = worksheets[0]
  y = 1
  call_numbers = []
  erc_information = {}
  until source_worksheet[y].nil?
    call_numbers << source_worksheet[y][0].value
    erc_information[source_worksheet[y][0].value] = { erc_who: source_worksheet[y][2].value.to_s,
                                                      erc_what: source_worksheet[y][3].value.to_s,
                                                      erc_when: source_worksheet[y][4].value.to_s }
    y += 1
  end

  call_numbers.each do |cn|
    ark_id = mint_arkid(erc_information[cn])
    erc_information[cn].merge!({:call_number => cn, :ark_id => ark_id.id})
  end

  erc_information.each_with_index do |(erc_key, value_set), y_index|
    value_set.each do |key, value|
      worksheet.add_cell(y_index+1, HEADERS.find_index { |k,_| k == key }, value)
    end
  end

end


Ezid::Client.configure do |conf|
  conf.default_shoulder = 'ark:/99999/fk4' unless ENV['EZID_DEFAULT_SHOULDER']
  conf.user = 'apitest' unless ENV['EZID_USER']
  conf.password = 'apitest' unless ENV['EZID_PASSWORD']
end

HEADERS = { :call_number => 'MMS_ID',
                      :ark_id => 'ARK',
                      :erc_who => 'Who',
                      :erc_what => 'What',
                      :erc_when => 'When'
}

abort('!!!!!!!!!! SEE ERROR BELOW !!!!!!!!!!
Specify a path to an Excel spreadsheet to read from and the path to write the new file to (MUST BE DIFFERENT FROM SOURCE EXCEL FILE)
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!') if missing_args?

spreadsheet_name = ARGV[1].to_s.end_with?('.xlsx') ? ARGV[1].to_s : "#{ARGV[1]}.xlsx"

source_workbook = ARGV[0]

abort("#{source_workbook} not found") unless File.exist?(source_workbook)

dataset = RubyXL::Parser.parse(source_workbook)

puts 'Writing spreadsheet...'
workbook.set_up_spreadsheet
workbook.populate(dataset)
workbook.write(spreadsheet_name)
puts "Spreadsheet written to #{spreadsheet_name}."