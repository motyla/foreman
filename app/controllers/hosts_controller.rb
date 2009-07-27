class HostsController < ApplicationController
  active_scaffold  :host do |config|
    config.list.columns = [:name, :operatingsystem, :environment, :last_compile ]
    config.columns = %w{ name ip mac hosttype operatingsystem environment architecture media domain model subnet root_pass serial puppetmaster disk comment}
    config.columns[:architecture].form_ui  = :select
    config.columns[:media].form_ui  = :select
    config.columns[:model].form_ui  = :select
    config.columns[:domain].form_ui  = :select
    config.columns[:subnet].form_ui  = :select
    config.columns[:hosttype].form_ui  = :select
    config.columns[:environment].form_ui  = :select
    config.columns[:operatingsystem].form_ui  = :select
    config.columns[:fact_values].association.reverse = :host
    config.nested.add_link("Inventory", [:fact_values])
  end

  def externalNodes
    if params.has_key? "fqdn"
      fqdn = params.delete "fqdn"
    else
      head(:bad_request) and return
    end
    host = Host.find_by_name fqdn.split(".")[0]
    param = {}
    param[:puppetmaster] = host.puppetmaster
    param[:longsitename] = host.domain.fullname
    param[:hostmode] = host.environment.name
    puppetclasses = []
    puppetclasses << host.hosttype.name
    render :text => Hash['classes' => puppetclasses, 'parameters' => param].to_yaml and return
  end
end
