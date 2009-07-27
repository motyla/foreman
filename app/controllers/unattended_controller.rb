class UnattendedController < ApplicationController
  layout nil
  before_filter :get_host_details

  def kickstart
    logger.info "#{controller_name}: Kickstart host #{@host.name}"
    @osver = @host.operatingsystem.major
    @arch = @host.architecture.name
    @diskLayout = @host.disk
  end

  def jumpstart
  end

  def preseed
  end

  def built
    logger.info "#{controller_name}: #{@host.name} is Built!"
    @host.built
    head(:created) and return
  end

  private
  # lookup for a host based on the ip address and if possible by a mac address(as sent by anaconda)
  # if the host was found than its record will be in @host
  # if the host doesn't exists, it will return 404 and the requested method will not be reached.

  def get_host_details
    # find out ip info
    if params.has_key? "spoof"
      ip = params.delete("spoof")
    elsif (ip = request.env['REMOTE_ADDR']) =~ /127.0.0/
      ip = request.env["HTTP_X_FORWARDED_FOR"] unless request.env["HTTP_X_FORWARDED_FOR"].nil?
    end

    unless request.env['HTTP_X_RHN_PROVISIONING_MAC_0'].nil?
      mac=request.env['HTTP_X_RHN_PROVISIONING_MAC_0'].split[1].downcase.strip
    end

    conditions = (mac and ip) ? ["mac = ? and ip = ?",mac, ip] : ["ip = ?",ip];
    @host = Host.find(:first, :include => [:architecture, :media, :operatingsystem, :domain], :conditions => conditions)
    if @host.nil?
      logger.info "#{controller_name}: unable to find #{ip}#{"/"+mac unless mac.nil?}"
      head(:not_found) and return
    end
  end

end
