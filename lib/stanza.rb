module Stanza
  class << self
    def find(id)
      "#{id.camelize}Stanza".constantize
    end

    def all
      Stanza::Base.descendants
    end

    def load_all!
      Dir[root.join('*_stanza.rb')].each do |f|
        require f
      end
    end

    def root
      Rails.root.join('app/stanza')
    end
  end
end

require 'stanza/base'
