require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'




def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"
    
    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

def clean_phone_numbers(phone_num)
    #remove non-digits from string
    phone_num = phone_num.gsub(/\D/, '')
    if phone_num.length == 10
        phone_num
    elsif phone_num.length == 11 && phone_num[0] == 1
        phone_num = phone_num[1..10]
    elsif phone_num.length == 11 && phone_num[0] != 1
        phone_num = "Invalid phone number"
    elsif phone_num.length > 11
        phone_num = "Invalid phone number"
    else 
        phone_num = "Invalid phone number"
    end

end

def time_targeting(times)
    times_hash = times.reduce(Hash.new(0)) do |hour, regs|
        hour[regs] += 1
        hour
    end
   times_hash.sort_by { |k, v| v }.reverse
   busiest_hour = times_hash.max_by{ |k, v| v }[0]
   p busiest_hour
end

def day_of_the_week_targeting(days)
    days_hash = days.reduce(Hash.new(0)) do |day, regs|
        day[regs] += 1
        day
    end
    days_hash.sort_by { |k, v| v }.reverse
    busiest_day = days_hash.max_by{ |k, v| v }[0]
    Date::DAYNAMES[busiest_day]
end

puts 'EventManager Initialized!'

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
times =[]
days = []
contents.each do |row|
    id = row[0]
    name = row[:first_name]
    phone = row[:homephone]
    regdate = row[:regdate]

    zipcode = clean_zipcode(row[:zipcode])
    clean_phone_numbers(phone)

    legislators = legislators_by_zipcode(zipcode)
    
    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)

    time = Time.strptime("#{regdate}", "%m/%d/%Y %k:%M").hour
    times.push(time)
    
    day = Time.strptime("#{regdate}", "%m/%d/%Y %k:%M").wday
    days.push(day)
   
end


puts "The busiest sign up time was #{time_targeting(times)} o'clock"
puts "The busiest sign up day was #{day_of_the_week_targeting(days)}"