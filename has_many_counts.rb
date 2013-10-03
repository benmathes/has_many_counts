module HasManyCounts
  attr_reader :has_many_counts
  def has_many_counts
    counts = {}
    self.class.reflect_on_all_associations(:has_many).each do |has_many|
      counts[has_many.name] = self.send(has_many.name).try(:count)
    end
    counts
  end

  # to include the class method too, see:
  # http://www.railstips.org/blog/archives/2009/05/15/include-vs-extend-in-ruby/
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # given a collection of objects,
    # @param  [< ActiveRecord::Base]
    # @return [Hash]
    def has_many_counts_for_collection(collection)
      return {} if collection.empty?

      has_many_collection_counts = {}
      self.reflect_on_all_associations(:has_many).each do |has_many|
        has_many_collection_counts[has_many.name] = has_many.klass.where(
          [
            "#{has_many.table_name}.#{has_many.foreign_key} in (?)",
            collection.map{|item| item.send(item.class.primary_key)}
          ]
        )
        .group(has_many.foreign_key)
        .count(has_many.klass.primary_key)
      end

      has_many_by_collection_id = {}
      has_many_collection_counts.each do |has_many_name, collection_id_to_count|
        collection_id_to_count.each do |item_id, count|
          has_many_by_collection_id[item_id] ||= {}
          has_many_by_collection_id[item_id][has_many_name] = count
        end
      end

      has_many_by_collection_id
    end
  end
end

