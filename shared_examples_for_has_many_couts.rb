hared_examples "has_many_counts" do

  # we don't care about validation, just counts,
  # so save to the DB without validation
  let(:item) { described_class.new.save(validate: false) }
  let(:has_manies_should) do
    has_manies_should = {}
    item.class.reflect_on_all_associations(:has_many).each_with_index do |has_many, i|
      num_to_create = i + 1
      num_to_create.times{ has_many.klass.new().save(validate: false) }
      has_manies_should[has_many.name] = num_to_create
    end
  end

  context '#has_many_counts' do
    it "should count number of has_many's" do
      puts item.inspect
      puts item.has_many_counts.inspect
      1.should == 1
    end
  end

  context '.has_many_counts_for_collection' do
    it "should count number of has_many's for entire collection" do
      puts item.inspect
      grouped_by_item_id = item.class.has_many_counts_for_collection([item])
      puts grouped_by_item_id.inspect
      1.should == 1
    end
  end

end
