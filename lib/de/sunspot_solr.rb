require 'de/sunspot_solr/operand'
require 'de/sunspot_solr/operator'
require 'de/sunspot_solr/search'

class String
  def escape_apos
    self.gsub(/'/, "\\\\'")
  end
end