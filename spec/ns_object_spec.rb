describe "the ns object hack router" do
  it "alias method trick works" do
    object = "hello"
    side_effect = false

    object.add_block_method :new_upcase! do
      side_effect = true
    end

    object.instance_eval do
      def upcase!
        new_upcase!
        super
      end
    end

    object.upcase!
    side_effect.should == true
    object.should == "HELLO"
  end
end