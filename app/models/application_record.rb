# Default models go to primary db
# To write to other dbs use: connects_to database { writing: :<cache/queue/cable> }
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
