module HasManyCounts
  attr_reader :has_many_counts

  # @param [ActiveRecord::Base]
  # @return [Hash] { has_many_relation_name => count }
  def has_many_counts(options = {})
    self.class.has_many_counts_for_collection([self], options)[self.send(self.class.primary_key)]
  end

  # to include the class method too, see:
  # http://www.railstips.org/blog/archives/2009/05/15/include-vs-extend-in-ruby/
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # given a collection of Objects, returns { object.id => { has_many_relation_name => relation.where(belongs_to object).count }
    # @param  [< ActiveRecord::Base]
    # @return [Hash]
    def has_many_counts_for_collection(collection, options = {})
      return {} if collection.empty?

      options = {unscoped: false}.merge(options)

      has_many_collection_counts = {}
      self.reflect_on_all_associations(:has_many).each do |has_many|
        arel = options[:unscoped] ? has_many.klass.unscoped : has_many.klass
        has_many_collection_counts[has_many.name] = arel.where(
          [
            "#{has_many.table_name}.#{has_many.foreign_key} in (?) and #{has_many.sanitized_conditions || '1 = 1'}",
            collection.map { |item| item.send(item.class.primary_key) }
          ]
        ).group(has_many.foreign_key).count(has_many.klass.primary_key)
      end

      has_many_by_collection_id = {}
      has_many_collection_counts.each do |has_many_name, collection_id_to_count|
        collection_id_to_count.each do |item_id, count|
          has_many_by_collection_id[item_id]                ||= {}
          has_many_by_collection_id[item_id][has_many_name] = count
        end
      end

      has_many_by_collection_id
    end

    # given a collection of objects, modifies collection so collection.first.has_many_counts pulls
    # @param  [< ActiveRecord::Base]
    # @return [Hash]
    def has_many_counts_for_collection!(collection, options = {})
      return {} if collection.empty?
      counts = self.has_many_counts_for_collection(collection, options)
      collection.each do |instance|

        # set a cached value for this instance
        instance.instance_eval do
          @cached_count = counts[instance.send(instance.class.primary_key)]
        end

        # override has_many_counts to return the cached version
        def instance.has_many_counts
          @cached_count
        end
      end
    end
  end
end
