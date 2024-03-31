require 'json'

# Read JSON file and return the parsed content w error handling
def read_json_file(file_path)
  JSON.parse(File.read(file_path))
rescue JSON::ParserError => e
  puts "Error parsing JSON from file #{file_path}: #{e.message}"
  []
end

# Write content to file (arg for file_path for flexibility and reusability in larger codebases)
def write_to_file(content, file_path)
  File.open(file_path, 'w') { |file| file.write(content) }
end

# Process user info and return formatted string based of example_output.txt
def process_user_info(users, top_up)
  users.map do |user|
    new_balance = user['tokens'] + top_up
    ["\t#{user['last_name']}, #{user['first_name']}, #{user['email']}",
     "\t  Previous Token Balance, #{user['tokens']}",
     "\t  New Token Balance #{new_balance}"].join("\n")
  end.join("\n")
end

def process_data(users, companies)
  # sort companies based off Ids and map through each company
  companies.sort_by { |company| company['id'] }.map do |company|
    # select active users for each company
    active_users = users.select { |user| user['company_id'] == company['id'] && user['active_status'] }
    # skip company if no active users
    next if active_users.empty?
    # sort users by last name
    active_users.sort_by! { |user| user['last_name'] }
    #  partition active users based on email status
    emailed_users, not_emailed_users = active_users.partition { |user| company['email_status'] && user['email_status'] }
    # if users are empty, set to None, otherwise list users with process_user_info for both emailed and not emailed users
    emailed_section = emailed_users.empty? ? "Users Emailed: None" : "Users Emailed:\n#{process_user_info(emailed_users, company['top_up'])}"
    not_emailed_section = "Users Not Emailed:\n#{process_user_info(not_emailed_users, company['top_up'])}" unless not_emailed_users.empty?
    # for company top up
    total_top_up = active_users.size * company['top_up']
    # end of company map with formatted string
    ["Company Id: #{company['id']}", 
     "Company Name: #{company['name']}", 
     emailed_section,
     not_emailed_section,
     "\tTotal amount of top ups for #{company['name']}: #{total_top_up}"].compact.join("\n")
  end.compact.join("\n\n")
end

# Main function to read files, process data and write to output file
def main
  users = read_json_file('users.json')
  companies = read_json_file('companies.json')
  output_content = process_data(users, companies)
  write_to_file(output_content, 'output.txt')
  puts 'Processing complete. Output saved to output.txt'
end

main
