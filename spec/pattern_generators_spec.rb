require 'spec_helper'

describe "basic parsing" do
  include TestParserGenerator

  it "test_many" do
    BabelBridge::Parser.many(";").hash.should == {:many=>";",:match=>true}
  end

  it "test_many?" do
    BabelBridge::Parser.many?(";").hash.should == {:many=>";", :optionally=>true, :match=>true}
  end

  it "test_match" do
    BabelBridge::Parser.match(";").hash.should == {:match=>";"}
  end

  it "test_match?" do
    BabelBridge::Parser.match?(";").hash.should == {:match=>";",:optionally=>true}
  end

  it "test_match!" do
    BabelBridge::Parser.match!(";").hash.should == {:match=>";",:dont=>true}
  end

  it "test_dont" do
    BabelBridge::Parser.dont.match(";").hash.should == {:match=>";",:dont=>true}
  end

  it "test_optionally" do
    BabelBridge::Parser.optionally.match(";").hash.should == {:match=>";",:optionally=>true}
  end

  it "test_could" do
    BabelBridge::Parser.could.match(";").hash.should == {:match=>";",:could=>true}
  end

  it "test_any" do
    BabelBridge::Parser.any(";").hash.should == {:any=>[";"]}
  end
end
