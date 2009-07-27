class Host < Puppet::Rails::Host
  belongs_to :architecture
  belongs_to :media
  belongs_to :model
  belongs_to :domain
  belongs_to :operatingsystem
  belongs_to :hosttype
  belongs_to :environment
  belongs_to :subnet

  # we originally used hostname, puppet uses name in its host table
  # TODO, rename all hostname to name, this is a workaround for now
  alias_attribute :hostname, :name 

  validates_uniqueness_of  :ip
  validates_uniqueness_of  :mac
  validates_uniqueness_of  :sp_mac, :allow_nil => true, :allow_blank => true
  validates_uniqueness_of  :sp_name, :sp_ip, :allow_blank => true, :allow_nil => true
  validates_uniqueness_of  :name
  validates_format_of      :sp_name, :with => /.*-sp/, :allow_nil => true, :allow_blank => true
  validates_presence_of    :name, :architecture
  validates_length_of      :root_pass, :minimum => 8,:too_short => 'should be 8 characters or more'
  validates_format_of      :mac,       :with => /([a-f0-9]{1,2}:){5}[a-f0-9]{1,2}/
  validates_format_of      :ip,        :with => /(\d{1,3}\.){3}\d{1,3}/
  validates_format_of      :sp_mac,    :with => /([a-f0-9]{1,2}:){5}[a-f0-9]{1,2}/, :allow_nil => true, :allow_blank => true
  validates_format_of      :sp_ip,     :with => /(\d{1,3}\.){3}\d{1,3}/, :allow_nil => true, :allow_blank => true
  validates_format_of      :serial,    :with => /[01],\d{3,}n\d/, :message => "should follow this format: 0,9600n8", :allow_blank => true, :allow_nil => true
  validates_associated     :domain, :operatingsystem,  :architecture, :subnet,:media#, :user, :deployment, :model

  before_validation :normalize_macaddresses

  # Returns the name of this host as a string
  # String: the host's name
  def to_label
    self.name
  end

  # Returns the name of this host as a string
  # String: the host's name
  def to_s
    self.to_label
  end

  def clearReports
    # Remove any reports that may be held against this host
    # self.reports.each{|report| report.destroy}
  end

  def clearFacts
    self.fact_values.each {|fv| fv.destroy}
  end

  # Called from the host build post install process to indicate that the base build has completed
  # Build is cleared and the boot link and autosign entries are removed
  # A site specific build script is called at this stage that can do site specific tasks
  def built
    self.build = false
    self.installed_at = Time.now.utc
    clearReports
    clearFacts
    save
    site_post_built = "#{$settings[:modulepath]}sites/#{self.domain.fullname.downcase}/built.sh"
      if File.executable? site_post_built
        %x{#{site_post_built} #{self.name} >> #{$settings[:logfile]} 2>&1 &}
      end
    # This can generate exceptions, so place it at the end of the sequence of operations
    #setAutosign
  end

  # no need to store anything in the db if the entry is plain "puppet"
  def puppetmaster
    self.read_attribute(:puppetmaster) || "puppet"
  end

  # no need to store anything in the db if the password is our default
  def root_pass
    self.read_attribute(:root_pass) || "my default password"
  end

  # sets basic default values
  def after_initialize
    self.architecture ||= Architecture.first
    self.operatingsystem ||= Operatingsystem.first
    self.media ||= Media.first
    self.domain ||= Domain.first
    self.build ||= true
  end

  def fqdn
    "#{self.name}.#{self.domain.name}"
  end

  # returns the host correct disk layout, custom or common
  def diskLayout
    @host.disk
    #@host.disk.empty? ? @host.ptable.body : @host.disk
  end

  private
  # align common mac and ip address input
  def normalize_macaddresses
    [mac,sp_mac].each do |m|
      unless m.empty?
        m.downcase!
        if m=~/[a-f0-9]{12}/
          m = m.gsub(/(..)/){|mh| mh + ":"}[/.{17}/]
        elsif mac=~/([a-f0-9]{1,2}:){5}[a-f0-9]{1,2}/
          m = m.split(":").map{|nibble| "%02x" % ("0x" + nibble)}.join(":")
        end
      end
    end

    [ip,sp_ip].each do |i|
      unless ip.empty?
        i = self.ip.split(".").map{|nibble| nibble.to_i}.join(".") if i=~/(\d{1,3}\.){3}\d{1,3}/
      end
    end
  end

end
