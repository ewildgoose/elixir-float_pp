defmodule FloatPPTest do
  use ExUnit.Case

  test "Simple float test" do
    assert IO.iodata_to_binary(FloatPP.to_string(1.2)) == "1.2"
  end

  test "small float" do
    assert IO.iodata_to_binary(FloatPP.to_string(0.000001)) == "0.000001"
  end

  test "small negative float" do
    assert IO.iodata_to_binary(FloatPP.to_string(-0.000001)) == "-0.000001"
  end

  test "large float test" do
    assert IO.iodata_to_binary(FloatPP.to_string(10000.0)) == "10000.0"
  end

  # test frexp/1
  test "test frexp(zero)" do
    {0.0, 0} = FloatPP.frexp(0.0)
  end

  test "test frexp(one)" do
    {0.5, 1} = FloatPP.frexp(1.0)
  end

  test "test frexp(negative one)" do
    {-0.5, 1} = FloatPP.frexp(-1.0)
  end

  test "test frexp(small denormalized number)" do
    # 4.94065645841246544177e-324
    <<small_denorm::float>> = <<0,0,0,0,0,0,0,1>>
    {0.5, -1073} = FloatPP.frexp(small_denorm)
  end

  test "test frexp(large denormalized number)" do
    # 2.22507385850720088902e-308
    <<big_denorm::float>> = <<0,15,255,255,255,255,255,255>>
    {0.99999999999999978, -1022} = FloatPP.frexp(big_denorm)
  end

  test "test frexp(small normalized number)" do
    # 2.22507385850720138309e-308
    <<small_norm::float>> = <<0,16,0,0,0,0,0,0>>
    {0.5, -1021} = FloatPP.frexp(small_norm)
  end

  test "test frexp(large normalized number)" do
    # 1.79769313486231570815e+308
    <<large_norm::float>> = <<127,239,255,255,255,255,255,255>>
    {0.99999999999999989, 1024} = FloatPP.frexp(large_norm)
  end

end
