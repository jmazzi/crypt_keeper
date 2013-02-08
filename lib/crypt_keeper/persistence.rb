module CryptKeeper
  module Persistence

    def self.set_persistence(base)
      hierarchy = base.ancestors.map {|klass| klass.to_s}

      if hierarchy.include? 'ActiveRecord::Base'
        base.send(:include, CryptKeeper::Persistence::ActiveRecordPersistence)
      elsif hierarchy.include? 'Mongoid::Document'
        base.send(:include, CryptKeeper::Persistence::MongoidPersistence)
      end
    end
  end
end
