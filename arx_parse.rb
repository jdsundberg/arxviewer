def remove_head_token(string)
#  string = markup_string(string)
  
  # we are in an empty string with trailing space
  if (/^"" /).match(string) then 
    new_string = string.reverse.chop.chop.chop.reverse
    return ["",new_string]
  end

  # we are in an empty string with trailing space
  # (assuming no space to be removed)
  if (/^""/).match(string) then 
    new_string = string.reverse.chop.chop.reverse
    return ["",new_string]
  end
  
  # we are in a string
  if(/^"/.match(string))  then
    # There is always a trailing space
    tmp_array = string.split(/"((?:\\.|[^\\"])*)"/)
    # tmp_array[1] is always an empty string ???
    tmp_array.shift
    token = tmp_array.shift
    string.slice!(0,token.size+3) # includes the 2 quotes and space
    return [token,string]
  end

  # not in a string
  tmp_array=string.split(/ /)
  token = tmp_array.shift
  new_string = tmp_array.join(" ")
  return [token,new_string]
end

def parse_arx_data(line)
  data = Array.new
  line.chomp!

  while true do 
    (token,line) = remove_head_token(line)
    data << token
    if (line.nil? || line.length == 0) then 
      break
    end
  end

  # remove DATA token 
  data.shift
  return data

end


def parse_arx_display(arx_file)
  return parse_arx(arx_file, false)
end

def parse_arx_meta(arx_file)
  return parse_arx(arx_file, true)
end

def parse_arx(arx_file,skip)
# Skip is no longer relevant - as I want to analyze the data - so we always
# read the entire file

  meta = Hash.new
  meta["data"]=Array.new
  meta["analysis_has_data"]=Array.new
  meta["analysis_missing_data"]=Array.new
  counter = 0
  status_history_index = nil
  begin
    file = File.new(arx_file,"r")
    while (line=file.gets)
      
      line.chomp!
      
      if (/^DATA /.match(line)) then
        counter = counter + 1

          parsed_line = parse_arx_data(line)
          meta["data"] << parsed_line

          # Look for missing and existing data
          parsed_line.each_with_index do |element,index|
            if (element.nil? || element.size == 0) then
              meta["analysis_missing_data"][index] = true
            else
              meta["analysis_has_data"][index] = true
            end
            
          end

      end

      if (/^SCHEMA "(.*)"/.match(line)) then
        meta['schema'] = $1
      end

      if (/^FIELDS "(.*)"/.match(line)) then
        fields = Array.new
        fields = $1.split(/" "/)
        meta['fields'] = fields
      end

      if (/^FLD-ID (.*)/.match(line)) then
        fieldid = Array.new
        fieldid = $1.split(/ /)
        meta['fieldid'] = fieldid
        status_history_index = meta['fieldid'].find_index("15")
      end

      if (/^DTYPES (.*)/.match(line)) then
        dtypes = Array.new
        dtypes = $1.split(/ /)
        meta['dtypes'] = dtypes
        if (status_history_index!=nil) then
          meta['dtypes'][status_history_index] = "STATUSHISTORY"
        end
      end
    end
    file.close
  rescue => err
    puts "Exception #{err}"
  end
  
  
  meta["data_count"] = counter

  return meta  
end


