shared_examples "has_many_counts" do

  # instantiate an instance of the described_class, and create
  # differing numbers of has_many relations to check has_many_counts against.
  before(:each) do

    # we don't care about validation, just counts,
    # so save to the DB without validation.
    @instance = described_class.new
    @instance.save(validate: false)

    @has_many_counts_ideal = {}
    @instance.class.reflect_on_all_associations(:has_many).each_with_index do |has_many, i|
      num_to_create = i + 1
      num_to_create.times do

        new_attributes = {}
        # set foreign key
        new_attributes[has_many.foreign_key] = @instance.send(@instance.class.primary_key)

        # set any non-null columns to arbitrary values.
        has_many.klass.columns.reject(&:primary).reject(&:null).each do |column|
          arbitrary_value = case column.type
            # special ase some types that don't have an equivalent .new()
            when :integer, :binary, :timestamp
              1
            when :text
              "arbitrary"
            when :datetime
              DateTime.new
            when :decimal, :float
              1.5
            else
              column.type.to_s.titleize.constantize.new
          end
          new_attributes[column.name] = arbitrary_value
        end

        # we don't care about validation, just counts,
        # so save to the DB without validation.
        new_child = has_many.klass.new(new_attributes)
        new_child.save(validate: false)
      end
      @has_many_counts_ideal[has_many.name] = num_to_create
    end
  end

  context '#has_many_counts' do
    it "should count number of has_many's" do
      @instance.inspect
      @instance.has_many_counts(unscoped: true).should == @has_many_counts_ideal
    end
  end

  context '.has_many_counts_for_collection' do
    it "should count number of has_many's for entire collection" do
      grouped_by_instance_id = @instance.class.has_many_counts_for_collection([@instance], unscoped: true)
      # should be { :id => @instance.has_many_counts }
      grouped_by_instance_id[@instance.send(@instance.class.primary_key)].should == @has_many_counts_ideal
    end
  end

end
