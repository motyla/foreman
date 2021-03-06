module HostsHelper
  def last_report_column(record)
    time_ago_in_words record.last_report.getlocal unless record.last_report.nil?
  end
  def root_pass_form_column(record, field_name)
      password_field_tag field_name, record.root_pass
  end

# method that reformats the hostname column by adding the status icons
  def name_column(record)
    if record.build and not record.installed_at.nil?
      image ="attention_required.png"
      title = "Pending Installation"
    elsif (os=record.fv(:kernel)).nil?
      image = "warning.png"
      title = "No Inventory Data"
    else
      image = "#{os}.jpg"
      title = os
    end
    image_tag("hosts/#{image}", :size => "18x18", :title => title) +
      link_to(record.shortname, :action => "edit", :id => record)
  end

end
